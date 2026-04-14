;; usdcx-pool.clar
;; Aurespend Pool Contract

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ERRORS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-constant ERR-INVALID-AMOUNT (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; STORAGE (REAL POOL STRUCTURE)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-map pool-balances
  { user: principal }
  { balance: uint }
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; POOL FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Deposit into pool
(define-public (deposit (amount uint))
  (begin
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)

    ;; Note: In Clarity 1, contract cannot receive STX directly; balance tracking only

    (let (
          (current (default-to u0 (get balance (map-get? pool-balances { user: tx-sender }))))
         )
      (map-set pool-balances
        { user: tx-sender }
        { balance: (+ current amount) }
      )
    )

    (print {
      event: "deposit",
      user: tx-sender,
      amount: amount
    })

    (ok true)
  )
)

;; Withdraw from pool
(define-public (withdraw (amount uint))
  (let (
        (caller tx-sender)
        (current (default-to u0 (get balance (map-get? pool-balances { user: caller }))))
       )
    (begin
      (asserts! (>= current amount) ERR-INSUFFICIENT-BALANCE)

      ;; Note: In Clarity 1, contract cannot send STX; balance tracking only

      (map-set pool-balances
        { user: caller }
        { balance: (- current amount) }
      )

      (print {
        event: "withdraw",
        user: caller,
        amount: amount
      })

      (ok true)
    )
  )
)

;; Simple yield 
(define-public (claim-yield)
  (let (
        (caller tx-sender)
        (current (default-to u0 (get balance (map-get? pool-balances { user: caller }))))
        (reward (/ current u10)) ;; 10% mock yield
       )
    (begin
      (asserts! (> reward u0) ERR-INVALID-AMOUNT)

      ;; Note: In Clarity 1, contract cannot send STX; balance tracking only

      (print {
        event: "yield-claimed",
        user: caller,
        reward: reward
      })

      (ok reward)
    )
  )
)


(define-constant ERR-AMOUNT-TOO-LOW (err u101))
(define-constant MIN-TIP-AMOUNT     u1)

(define-public (transfer (recipient principal) (amount uint))
  (begin
    (asserts! (>= amount MIN-TIP-AMOUNT) ERR-AMOUNT-TOO-LOW)
    
    ;; Direct transfer (independent of pool)
    (try! (stx-transfer? amount tx-sender recipient))
    
    (print {
      event: "tip-sent",
      sender: tx-sender,
      recipient: recipient,
      amount: amount,
      memo: u"tip"
    })
    
    (ok true)
  )
)

(define-read-only (get-min-tip-amount)
  (ok MIN-TIP-AMOUNT)
)