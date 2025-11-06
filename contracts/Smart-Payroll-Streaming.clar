;; title: Smart-Payroll-Streaming

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-insufficient-balance (err u105))
(define-constant err-stream-ended (err u106))
(define-constant err-stream-active (err u107))
(define-constant err-invalid-duration (err u108))
(define-constant err-nothing-to-withdraw (err u109))
(define-constant err-stream-paused (err u110))
(define-constant err-stream-not-paused (err u111))

(define-map streams
  { stream-id: uint }
  {
    employer: principal,
    employee: principal,
    total-amount: uint,
    rate-per-block: uint,
    start-block: uint,
    end-block: uint,
    withdrawn: uint,
    active: bool,
    paused: bool,
    paused-at-block: uint,
    total-paused-blocks: uint
  }
)

(define-map employee-streams
  { employee: principal }
  { stream-ids: (list 100 uint) }
)

(define-map employer-streams
  { employer: principal }
  { stream-ids: (list 100 uint) }
)

(define-data-var stream-nonce uint u0)

(define-read-only (get-stream (stream-id uint))
  (map-get? streams { stream-id: stream-id })
)

(define-read-only (get-employee-streams (employee principal))
  (default-to { stream-ids: (list) } (map-get? employee-streams { employee: employee }))
)

(define-read-only (get-employer-streams (employer principal))
  (default-to { stream-ids: (list) } (map-get? employer-streams { employer: employer }))
)

(define-read-only (calculate-earned (stream-id uint))
  (let (
    (stream (unwrap! (get-stream stream-id) err-not-found))
    (current-block stacks-block-height)
    (effective-current-block (if (get paused stream)
                                 (get paused-at-block stream)
                                 current-block))
    (elapsed-blocks (if (<= effective-current-block (get start-block stream))
                        u0
                        (if (>= effective-current-block (get end-block stream))
                            (- (get end-block stream) (get start-block stream) (get total-paused-blocks stream))
                            (- effective-current-block (get start-block stream) (get total-paused-blocks stream)))))
    (total-earned (* elapsed-blocks (get rate-per-block stream)))
    (available (- total-earned (get withdrawn stream)))
  )
    (ok available)
  )
)

(define-read-only (get-stream-details (stream-id uint))
  (let (
    (stream (unwrap! (get-stream stream-id) err-not-found))
    (earned (unwrap! (calculate-earned stream-id) err-not-found))
  )
    (ok {
      employer: (get employer stream),
      employee: (get employee stream),
      total-amount: (get total-amount stream),
      rate-per-block: (get rate-per-block stream),
      start-block: (get start-block stream),
      end-block: (get end-block stream),
      withdrawn: (get withdrawn stream),
      available: earned,
      active: (get active stream),
      paused: (get paused stream),
      paused-at-block: (get paused-at-block stream),
      total-paused-blocks: (get total-paused-blocks stream)
    })
  )
)

(define-private (add-to-list (item uint) (current-list (list 100 uint)))
  (unwrap-panic (as-max-len? (append current-list item) u100))
)

(define-public (create-stream (employee principal) (total-amount uint) (duration-blocks uint))
  (let (
    (stream-id (var-get stream-nonce))
    (rate (/ total-amount duration-blocks))
    (start-block stacks-block-height)
    (end-block (+ start-block duration-blocks))
  )
    (asserts! (> total-amount u0) err-invalid-amount)
    (asserts! (> duration-blocks u0) err-invalid-duration)
    (asserts! (not (is-eq tx-sender employee)) err-unauthorized)
    
    (try! (stx-transfer? total-amount tx-sender (as-contract tx-sender)))
    
    (map-set streams
      { stream-id: stream-id }
      {
        employer: tx-sender,
        employee: employee,
        total-amount: total-amount,
        rate-per-block: rate,
        start-block: start-block,
        end-block: end-block,
        withdrawn: u0,
        active: true,
        paused: false,
        paused-at-block: u0,
        total-paused-blocks: u0
      }
    )
    
    (let (
      (employee-list (get stream-ids (get-employee-streams employee)))
      (employer-list (get stream-ids (get-employer-streams tx-sender)))
    )
      (map-set employee-streams
        { employee: employee }
        { stream-ids: (add-to-list stream-id employee-list) }
      )
      (map-set employer-streams
        { employer: tx-sender }
        { stream-ids: (add-to-list stream-id employer-list) }
      )
    )
    
    (var-set stream-nonce (+ stream-id u1))
    (ok stream-id)
  )
)

(define-public (withdraw (stream-id uint))
  (let (
    (stream (unwrap! (get-stream stream-id) err-not-found))
    (available (unwrap! (calculate-earned stream-id) err-not-found))
  )
    (asserts! (is-eq tx-sender (get employee stream)) err-unauthorized)
    (asserts! (get active stream) err-stream-ended)
    (asserts! (not (get paused stream)) err-stream-paused)
    (asserts! (> available u0) err-nothing-to-withdraw)
    
    (try! (as-contract (stx-transfer? available tx-sender (get employee stream))))
    
    (map-set streams
      { stream-id: stream-id }
      (merge stream { withdrawn: (+ (get withdrawn stream) available) })
    )
    
    (ok available)
  )
)

(define-public (cancel-stream (stream-id uint))
  (let (
    (stream (unwrap! (get-stream stream-id) err-not-found))
    (available (unwrap! (calculate-earned stream-id) err-not-found))
    (remaining (- (get total-amount stream) (get withdrawn stream) available))
  )
    (asserts! (is-eq tx-sender (get employer stream)) err-unauthorized)
    (asserts! (get active stream) err-stream-ended)
    
    (if (> available u0)
      (try! (as-contract (stx-transfer? available tx-sender (get employee stream))))
      true
    )
    
    (if (> remaining u0)
      (try! (as-contract (stx-transfer? remaining tx-sender (get employer stream))))
      true
    )
    
    (map-set streams
      { stream-id: stream-id }
      (merge stream {
        withdrawn: (+ (get withdrawn stream) available),
        active: false
      })
    )
    
    (ok true)
  )
)

(define-public (emergency-withdraw (stream-id uint))
  (let (
    (stream (unwrap! (get-stream stream-id) err-not-found))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (ok true)
  )
)

(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)

(define-read-only (get-total-streams)
  (ok (var-get stream-nonce))
)

(define-public (pause-stream (stream-id uint))
  (let (
    (stream (unwrap! (get-stream stream-id) err-not-found))
    (current-block stacks-block-height)
  )
    (asserts! (is-eq tx-sender (get employer stream)) err-unauthorized)
    (asserts! (get active stream) err-stream-ended)
    (asserts! (not (get paused stream)) err-stream-active)
    
    (map-set streams
      { stream-id: stream-id }
      (merge stream {
        paused: true,
        paused-at-block: current-block
      })
    )
    
    (ok true)
  )
)

(define-public (resume-stream (stream-id uint))
  (let (
    (stream (unwrap! (get-stream stream-id) err-not-found))
    (current-block stacks-block-height)
    (paused-duration (- current-block (get paused-at-block stream)))
    (new-total-paused (+ (get total-paused-blocks stream) paused-duration))
  )
    (asserts! (is-eq tx-sender (get employer stream)) err-unauthorized)
    (asserts! (get active stream) err-stream-ended)
    (asserts! (get paused stream) err-stream-not-paused)
    
    (map-set streams
      { stream-id: stream-id }
      (merge stream {
        paused: false,
        paused-at-block: u0,
        total-paused-blocks: new-total-paused
      })
    )
    
    (ok true)
  )
)
