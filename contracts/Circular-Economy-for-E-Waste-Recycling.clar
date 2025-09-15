(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-status (err u104))
(define-constant err-insufficient-balance (err u105))

(define-fungible-token eco-token)

(define-non-fungible-token product-passport uint)

(define-data-var next-product-id uint u1)
(define-data-var recycling-reward uint u100)

(define-map products 
  uint 
  {
    manufacturer: principal,
    device-type: (string-ascii 50),
    serial-number: (string-ascii 100),
    production-date: uint,
    status: (string-ascii 20),
    current-owner: principal,
    recycler: (optional principal)
  }
)

(define-map recyclers 
  principal 
  {
    name: (string-ascii 100),
    license-number: (string-ascii 50),
    certification-level: uint,
    total-recycled: uint,
    verified: bool,
    registered-at: uint
  }
)

(define-map user-balances principal uint)

(define-public (register-recycler (name (string-ascii 100)) (license-number (string-ascii 50)) (certification-level uint))
  (let ((caller tx-sender))
    (asserts! (is-none (map-get? recyclers caller)) err-already-exists)
    (map-set recyclers caller {
      name: name,
      license-number: license-number,
      certification-level: certification-level,
      total-recycled: u0,
      verified: false,
      registered-at: stacks-block-height
    })
    (ok caller)
  )
)

(define-public (verify-recycler (recycler principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-some (map-get? recyclers recycler)) err-not-found)
    (map-set recyclers recycler 
      (merge (unwrap-panic (map-get? recyclers recycler)) {verified: true})
    )
    (ok true)
  )
)

(define-public (create-product-passport 
  (device-type (string-ascii 50)) 
  (serial-number (string-ascii 100))
  (production-date uint)
)
  (let 
    (
      (product-id (var-get next-product-id))
      (manufacturer tx-sender)
    )
    (try! (nft-mint? product-passport product-id manufacturer))
    (map-set products product-id {
      manufacturer: manufacturer,
      device-type: device-type,
      serial-number: serial-number,
      production-date: production-date,
      status: "produced",
      current-owner: manufacturer,
      recycler: none
    })
    (var-set next-product-id (+ product-id u1))
    (ok product-id)
  )
)

(define-public (transfer-product (product-id uint) (new-owner principal))
  (let ((product (unwrap! (map-get? products product-id) err-not-found)))
    (asserts! (is-eq (get current-owner product) tx-sender) err-unauthorized)
    (asserts! (not (is-eq (get status product) "recalled")) err-unauthorized)
    (try! (nft-transfer? product-passport product-id tx-sender new-owner))
    (map-set products product-id
      (merge product {
        current-owner: new-owner,
        status: "transferred"
      })
    )
    (ok true)
  )
)

(define-public (update-product-status (product-id uint) (new-status (string-ascii 20)))
  (let ((product (unwrap! (map-get? products product-id) err-not-found)))
    (asserts! (is-eq (get current-owner product) tx-sender) err-unauthorized)
    (map-set products product-id (merge product {status: new-status}))
    (ok true)
  )
)

(define-public (initiate-recycling (product-id uint) (recycler principal))
  (let 
    (
      (product (unwrap! (map-get? products product-id) err-not-found))
      (recycler-info (unwrap! (map-get? recyclers recycler) err-not-found))
    )
    (asserts! (is-eq (get current-owner product) tx-sender) err-unauthorized)
    (asserts! (get verified recycler-info) err-unauthorized)
    (asserts! (is-eq (get status product) "end-of-life") err-invalid-status)
    
    (map-set products product-id 
      (merge product {
        status: "recycling",
        recycler: (some recycler)
      })
    )
    (ok true)
  )
)

(define-public (complete-recycling (product-id uint))
  (let 
    (
      (product (unwrap! (map-get? products product-id) err-not-found))
      (recycler-principal (unwrap! (get recycler product) err-not-found))
      (recycler-info (unwrap! (map-get? recyclers recycler-principal) err-not-found))
      (reward-amount (var-get recycling-reward))
    )
    (asserts! (is-eq tx-sender recycler-principal) err-unauthorized)
    (asserts! (is-eq (get status product) "recycling") err-invalid-status)
    
    (map-set products product-id 
      (merge product {status: "recycled"})
    )
    
    (map-set recyclers recycler-principal 
      (merge recycler-info {total-recycled: (+ (get total-recycled recycler-info) u1)})
    )
    
    (try! (ft-mint? eco-token reward-amount recycler-principal))
    (try! (ft-mint? eco-token (/ reward-amount u2) (get current-owner product)))
    
    (ok reward-amount)
  )
)
(define-public (retire-product (product-id uint))
  (let ((product (unwrap! (map-get? products product-id) err-not-found)))
    (asserts! (is-eq tx-sender (unwrap! (get recycler product) err-unauthorized)) err-unauthorized)
    (asserts! (is-eq (get status product) "recycled") err-invalid-status)
    (try! (nft-burn? product-passport product-id tx-sender))
    (map-delete products product-id)
    (ok true)
  )
)

(define-public (recall-product (product-id uint))
  (let ((product (unwrap! (map-get? products product-id) err-not-found)))
    (asserts! (is-eq (get manufacturer product) tx-sender) err-unauthorized)
    (asserts! (not (is-eq (get status product) "recalled")) err-invalid-status)
    (map-set products product-id (merge product {status: "recalled"}))
    (ok true)
  )
)

(define-public (claim-recycling-reward (amount uint))
  (let ((current-balance (default-to u0 (map-get? user-balances tx-sender))))
    (asserts! (>= current-balance amount) err-insufficient-balance)
    (map-set user-balances tx-sender (- current-balance amount))
    (try! (ft-mint? eco-token amount tx-sender))
    (ok amount)
  )
)

(define-public (set-recycling-reward (new-reward uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set recycling-reward new-reward)
    (ok new-reward)
  )
)

(define-read-only (get-product-info (product-id uint))
  (map-get? products product-id)
)

(define-read-only (get-recycler-info (recycler principal))
  (map-get? recyclers recycler)
)

(define-read-only (get-user-balance (user principal))
  (default-to u0 (map-get? user-balances user))
)

(define-read-only (get-recycling-reward)
  (var-get recycling-reward)
)

(define-read-only (get-next-product-id)
  (var-get next-product-id)
)

(define-read-only (get-contract-owner)
  contract-owner
)

(define-read-only (get-total-supply)
  (ft-get-supply eco-token)
)

(define-read-only (get-product-owner (product-id uint))
  (nft-get-owner? product-passport product-id)
)

(define-read-only (is-verified-recycler (recycler principal))
  (match (map-get? recyclers recycler)
    recycler-info (get verified recycler-info)
    false
  )
)

(define-read-only (get-products-by-status (status (string-ascii 20)))
  (ok status)
)

(define-read-only (calculate-recycling-incentive (certification-level uint) (base-reward uint))
  (if (>= certification-level u3)
    (* base-reward u2)
    base-reward
  )
)
