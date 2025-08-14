(define-data-var next-campaign-id uint u1)

(define-map campaigns  
  { id: uint }  
  {    
    creator: principal,    
    goal: uint,    
    deadline: uint,    
    raised: uint,    
    claimed: bool  
  }
)

(define-map contributions  
  { id: uint, contributor: principal }  
  {    
    amount: uint  
  }
)

;; Create a new campaign
(define-public (create-campaign (goal uint) (duration uint))
  (let (
    (campaign-id (var-get next-campaign-id))
    (caller tx-sender)
    (deadline (+ stacks-block-height duration))
  )
    (begin
      ;; Validate inputs
      (asserts! (> goal u0) (err u200))
      (asserts! (> duration u0) (err u201))
      
      (map-set campaigns
        { id: campaign-id }
        {
          creator: caller,
          goal: goal,
          deadline: deadline,
          raised: u0,
          claimed: false
        }
      )
      (var-set next-campaign-id (+ campaign-id u1))
      (ok campaign-id)
    )
  )
)

;; Contribute to a campaign
(define-public (contribute (id uint) (amount uint))
  (let (
    (campaign (map-get? campaigns { id: id }))
    (existing-contrib (map-get? contributions { id: id, contributor: tx-sender }))
  )
    (match campaign c
      (begin
        ;; Check campaign is still active
        (asserts! (< stacks-block-height (get deadline c)) (err u100))
        ;; Check amount is positive
        (asserts! (> amount u0) (err u202))
        
        ;; Transfer STX from contributor to contract
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        ;; Update or create contribution record
        (let (
          (new-contrib-amount 
            (match existing-contrib existing
              (+ (get amount existing) amount)
              amount
            )
          )
        )
          (map-set contributions 
            { id: id, contributor: tx-sender }
            { amount: new-contrib-amount }
          )
          
          ;; Update campaign raised amount
          (map-set campaigns 
            { id: id }
            (merge c { raised: (+ (get raised c) amount) })
          )
          (ok true)
        )
      )
      (err u102) ;; Campaign not found
    )
  )
)

;; Claim funds if goal met and deadline passed
(define-public (claim-funds (id uint))
  (let ((campaign (map-get? campaigns { id: id })))
    (match campaign c
      (begin
        ;; Only creator can claim
        (asserts! (is-eq tx-sender (get creator c)) (err u103))
        ;; Goal must be met
        (asserts! (>= (get raised c) (get goal c)) (err u104))
        ;; Deadline must have passed
        (asserts! (>= stacks-block-height (get deadline c)) (err u105))
        ;; Funds not already claimed
        (asserts! (not (get claimed c)) (err u106))
        
        ;; Mark as claimed
        (map-set campaigns { id: id } (merge c { claimed: true }))
        
        ;; Transfer funds to creator
        (as-contract (stx-transfer? (get raised c) tx-sender (get creator c)))
      )
      (err u102) ;; Campaign not found
    )
  )
)

;; Claim refund if campaign failed
(define-public (claim-refund (id uint))
  (let (
    (campaign (map-get? campaigns { id: id }))
    (contrib (map-get? contributions { id: id, contributor: tx-sender }))
  )
    (match campaign c
      (match contrib a
        (begin
          ;; Campaign must have failed (goal not met)
          (asserts! (< (get raised c) (get goal c)) (err u107))
          ;; Deadline must have passed
          (asserts! (>= stacks-block-height (get deadline c)) (err u108))
          ;; Funds must not have been claimed by creator
          (asserts! (not (get claimed c)) (err u110))
          
          ;; Remove contribution record
          (map-delete contributions { id: id, contributor: tx-sender })
          
          ;; Refund the contributor
          (as-contract (stx-transfer? (get amount a) tx-sender tx-sender))
        )
        (err u109) ;; No contribution found
      )
      (err u102) ;; Campaign not found
    )
  )
)

;; Read-only functions
(define-read-only (get-campaign (id uint))
  (map-get? campaigns { id: id })
)

(define-read-only (get-contribution (id uint) (contributor principal))
  (map-get? contributions { id: id, contributor: contributor })
)

(define-read-only (get-next-campaign-id)
  (var-get next-campaign-id)
)

(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)

(define-read-only (campaign-status (id uint))
  (match (map-get? campaigns { id: id }) campaign
    (let (
      (goal-met (>= (get raised campaign) (get goal campaign)))
      (deadline-passed (>= stacks-block-height (get deadline campaign)))
      (is-claimed (get claimed campaign))
    )
      (ok {
        goal-met: goal-met,
        deadline-passed: deadline-passed,
        claimed: is-claimed,
        status: (if is-claimed
                  "claimed"
                  (if deadline-passed
                    (if goal-met "successful" "failed")
                    "active"))
      })
    )
    (err u102)
  )
)

;; Error codes:
;; u100: Campaign deadline has passed
;; u101: STX transfer failed  
;; u102: Campaign not found
;; u103: Only creator can claim funds
;; u104: Goal not reached
;; u105: Deadline not yet reached for claiming
;; u106: Funds already claimed
;; u107: Campaign succeeded, no refund available
;; u108: Deadline not yet reached for refund
;; u109: No contribution found for refund
;; u110: Funds already claimed by creator
;; u200: Goal must be greater than 0
;; u201: Duration must be greater than 0
;; u202: Contribution amount must be greater than 0
