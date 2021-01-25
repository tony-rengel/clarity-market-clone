(define-map monsters {monster-id: uint}
  {name: (string-ascii 20),
  last-meal: uint,
  image: uint}
)

(define-non-fungible-token nft-monsters uint)
(define-data-var next-id uint u1)
(define-constant hunger-tolerance u86400) ;; 1 day in seconds

(define-constant err-monster-unborn u1)
(define-constant err-monster-exists u2)
(define-constant err-monster-died u3)
(define-constant err-transfer-not-allowed u4)
(define-constant err-transfer-failed u5)

(define-private (get-time)
   (unwrap-panic (get-block-info? time (- block-height u1)))
)

(define-private (is-last-meal-young (last-meal uint))
  (> (to-int last-meal) (to-int (- (get-time) hunger-tolerance)))
)

(define-public (create-monster (name (string-ascii 20)) (image uint))
 (let ((monster-id (var-get next-id)))
      (if (is-ok (nft-mint? nft-monsters monster-id tx-sender))
        (begin
          (var-set next-id (+ monster-id u1))
          (map-set monsters {monster-id: monster-id}
            {
              name: name,
              last-meal: (get-time),
              image: image
            }
          )
          (ok monster-id)
        )
        (err err-monster-exists)
    )
  )
)

(define-public (feed-monster (monster-id uint))
  (match (map-get? monsters {monster-id: monster-id})
    monster (let ((last-meal (get-time)))
        (if (is-last-meal-young (get last-meal monster))
          (begin
            (map-set monsters {monster-id: monster-id} {
              name: (get name monster),
              last-meal: last-meal,
              image: (get image monster)
              }
            )
            (ok block-height)
          )
          (err err-monster-died)
        )
      )
    (err err-monster-unborn)
  )
)

(define-public (transfer (monster-id uint) (recipient principal))
  (let ((owner (unwrap! (owner-of? monster-id) (err err-monster-unborn))))
    (if (is-eq owner tx-sender)
      (match (nft-transfer? nft-monsters monster-id tx-sender recipient)
        success (ok true)
        error (err err-transfer-failed)
      )
      (err err-transfer-not-allowed)
    )
  )
)

(define-read-only (last-monster-id)
   (- (var-get next-id) u1)
)

(define-read-only (owner-of? (monster-id uint))
  (match (nft-get-owner? nft-monsters monster-id)
    owner (ok owner)
    (err err-monster-unborn)
  )
)

(define-read-only (is-alive (monster-id uint))
  (match (map-get? monsters {monster-id: monster-id})
    monster (ok (is-last-meal-young (get last-meal monster)))
    (err err-monster-unborn)
  )
)
