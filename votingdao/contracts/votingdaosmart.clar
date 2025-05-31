;; Decentralized Voting/DAO Smart Contract
;; Allows token holders to create and vote on proposals

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-not-found (err u301))
(define-constant err-unauthorized (err u302))
(define-constant err-invalid-amount (err u303))
(define-constant err-proposal-ended (err u304))
(define-constant err-already-voted (err u305))
(define-constant err-insufficient-tokens (err u306))
(define-constant err-invalid-input (err u307))

;; Data Variables
(define-data-var proposal-counter uint u0)
(define-data-var min-proposal-tokens uint u1000) ;; Minimum tokens to create proposal
(define-data-var voting-period uint u1440) ;; Voting period in blocks (~10 days)

;; Input validation functions
(define-private (is-valid-title (input (string-ascii 100)))
  (and (> (len input) u0) (<= (len input) u100))
)

(define-private (is-valid-description (input (string-ascii 500)))
  (and (> (len input) u0) (<= (len input) u500))
)

(define-private (is-valid-uint (input uint))
  (> input u0)
)

(define-private (is-valid-principal (input principal))
  (not (is-eq input contract-owner))
)

;; Data Maps
(define-map proposals
  { proposal-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    yes-votes: uint,
    no-votes: uint,
    start-block: uint,
    end-block: uint,
    status: (string-ascii 20),
    executed: bool
  }
)

(define-map votes
  { proposal-id: uint, voter: principal }
  {
    vote: bool,
    tokens: uint,
    block-height: uint
  }
)

(define-map token-balances
  { holder: principal }
  { balance: uint }
)

(define-map delegations
  { delegator: principal }
  { delegate: principal }
)

;; Public Functions

;; Mint tokens (for testing purposes)
(define-public (mint-tokens (recipient principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-valid-principal recipient) err-invalid-input)
    (asserts! (is-valid-uint amount) err-invalid-amount)
    
    (match (map-get? token-balances { holder: recipient })
      balance (map-set token-balances
        { holder: recipient }
        { balance: (+ (get balance balance) amount) }
      )
      (map-set token-balances
        { holder: recipient }
        { balance: amount }
      )
    )
    (ok true)
  )
)

;; Create a new proposal
(define-public (create-proposal (title (string-ascii 100)) (description (string-ascii 500)))
  (let
    (
      (proposal-id (+ (var-get proposal-counter) u1))
      (user-balance (default-to u0 (get balance (map-get? token-balances { holder: tx-sender }))))
    )
    (asserts! (is-valid-title title) err-invalid-input)
    (asserts! (is-valid-description description) err-invalid-input)
    (asserts! (>= user-balance (var-get min-proposal-tokens)) err-insufficient-tokens)
    
    (map-set proposals
      { proposal-id: proposal-id }
      {
        creator: tx-sender,
        title: title,
        description: description,
        yes-votes: u0,
        no-votes: u0,
        start-block: stacks-block-height,
        end-block: (+ stacks-block-height (var-get voting-period)),
        status: "active",
        executed: false
      }
    )
    (var-set proposal-counter proposal-id)
    (ok proposal-id)
  )
)

;; Vote on a proposal
(define-public (vote (proposal-id uint) (support bool))
  (let
    (
      (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-not-found))
      (user-balance (default-to u0 (get balance (map-get? token-balances { holder: tx-sender }))))
    )
    (asserts! (is-valid-uint proposal-id) err-invalid-input)
    (asserts! (is-eq (get status proposal) "active") err-proposal-ended)
    (asserts! (<= stacks-block-height (get end-block proposal)) err-proposal-ended)
    (asserts! (> user-balance u0) err-insufficient-tokens)
    (asserts! (is-none (map-get? votes { proposal-id: proposal-id, voter: tx-sender })) err-already-voted)
    
    ;; Record vote
    (map-set votes
      { proposal-id: proposal-id, voter: tx-sender }
      {
        vote: support,
        tokens: user-balance,
        block-height: stacks-block-height
      }
    )
    
    ;; Update proposal vote counts
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal {
        yes-votes: (if support (+ (get yes-votes proposal) user-balance) (get yes-votes proposal)),
        no-votes: (if support (get no-votes proposal) (+ (get no-votes proposal) user-balance))
      })
    )
    
    (ok true)
  )
)

;; Execute a proposal (if it passed)
(define-public (execute-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-not-found))
    )
    (asserts! (is-valid-uint proposal-id) err-invalid-input)
    (asserts! (> stacks-block-height (get end-block proposal)) err-proposal-ended)
    (asserts! (not (get executed proposal)) err-proposal-ended)
    (asserts! (> (get yes-votes proposal) (get no-votes proposal)) err-unauthorized)
    
    ;; Mark as executed
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal {
        status: "executed",
        executed: true
      })
    )
    
    (ok true)
  )
)

;; Delegate voting power
(define-public (delegate-vote (delegate principal))
  (begin
    (asserts! (is-valid-principal delegate) err-invalid-input)
    (asserts! (not (is-eq delegate tx-sender)) err-invalid-input)
    
    (map-set delegations
      { delegator: tx-sender }
      { delegate: delegate }
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes { proposal-id: proposal-id, voter: voter })
)

(define-read-only (get-token-balance (holder principal))
  (default-to u0 (get balance (map-get? token-balances { holder: holder })))
)

(define-read-only (get-proposal-counter)
  (var-get proposal-counter)
)
