;; EcoSync Contract
;; Platform for environmental initiatives

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-initiative (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-not-found (err u103))

;; Data vars
(define-data-var next-initiative-id uint u0)

;; Define token
(define-fungible-token eco-token)

;; Data maps
(define-map initiatives
    uint 
    {
        name: (string-ascii 100),
        description: (string-ascii 500),
        creator: principal,
        target: uint,
        progress: uint,
        active: bool,
        participants: uint
    }
)

(define-map participant-contributions
    {initiative-id: uint, participant: principal}
    {
        contributions: uint,
        tokens-earned: uint
    }
)

;; Public functions
(define-public (create-initiative (name (string-ascii 100)) (description (string-ascii 500)) (target uint))
    (let
        (
            (initiative-id (var-get next-initiative-id))
        )
        (asserts! (map-insert initiatives 
            initiative-id
            {
                name: name,
                description: description,
                creator: tx-sender,
                target: target,
                progress: u0,
                active: true,
                participants: u0
            }
        ) err-already-exists)
        (var-set next-initiative-id (+ initiative-id u1))
        (ok initiative-id)
    )
)

(define-public (join-initiative (initiative-id uint))
    (let
        (
            (initiative (unwrap! (map-get? initiatives initiative-id) err-not-found))
        )
        (asserts! (is-none (map-get? participant-contributions {initiative-id: initiative-id, participant: tx-sender})) err-already-exists)
        (map-set participant-contributions 
            {initiative-id: initiative-id, participant: tx-sender}
            {contributions: u0, tokens-earned: u0}
        )
        (map-set initiatives initiative-id
            (merge initiative {participants: (+ (get participants initiative) u1)})
        )
        (ok true)
    )
)

(define-public (log-contribution (initiative-id uint) (amount uint))
    (let
        (
            (initiative (unwrap! (map-get? initiatives initiative-id) err-not-found))
            (participant-data (unwrap! (map-get? participant-contributions {initiative-id: initiative-id, participant: tx-sender}) err-not-found))
            (tokens-to-mint (/ amount u10))
        )
        ;; Update initiative progress
        (map-set initiatives initiative-id
            (merge initiative {progress: (+ (get progress initiative) amount)})
        )
        ;; Update participant contributions
        (map-set participant-contributions 
            {initiative-id: initiative-id, participant: tx-sender}
            {
                contributions: (+ (get contributions participant-data) amount),
                tokens-earned: (+ (get tokens-earned participant-data) tokens-to-mint)
            }
        )
        ;; Mint eco-tokens as reward
        (try! (ft-mint? eco-token tokens-to-mint tx-sender))
        (ok true)
    )
)

;; Read only functions
(define-read-only (get-initiative (initiative-id uint))
    (ok (map-get? initiatives initiative-id))
)

(define-read-only (get-participant-stats (initiative-id uint) (participant principal))
    (ok (map-get? participant-contributions {initiative-id: initiative-id, participant: participant}))
)

(define-read-only (get-eco-balance (account principal))
    (ok (ft-get-balance eco-token account))
)