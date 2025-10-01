(define-constant ERR-NOT-FOUND (err u401))
(define-constant ERR-UNAUTHORIZED (err u402))
(define-constant ERR-ALREADY-CERTIFIED (err u403))
(define-constant ERR-INVALID-SCORE (err u404))

(define-data-var next-certificate-id uint u1)

(define-map certificates
  { certificate-id: uint }
  {
    student-id: uint,
    internship-id: uint,
    company-id: uint,
    performance-score: uint,
    completion-date: uint,
    duration-completed: uint,
    issued-by: principal,
    verification-hash: (buff 32)
  }
)

(define-map student-certificates
  { student-id: uint, internship-id: uint }
  { certificate-id: uint }
)

(define-map certificate-count
  { student-id: uint }
  { count: uint }
)

(define-public (issue-certificate (student-id uint) (internship-id uint) (performance-score uint))
  (let ((company-info (contract-call? .Decentralized-Intern-Matching-System get-company-by-wallet tx-sender))
        (internship-info (contract-call? .Decentralized-Intern-Matching-System get-internship internship-id))
        (student-info (contract-call? .Decentralized-Intern-Matching-System get-student student-id)))
    (asserts! (is-some company-info) ERR-UNAUTHORIZED)
    (asserts! (is-some internship-info) ERR-NOT-FOUND)
    (asserts! (is-some student-info) ERR-NOT-FOUND)
    (asserts! (<= performance-score u100) ERR-INVALID-SCORE)
    (asserts! (is-none (map-get? student-certificates { student-id: student-id, internship-id: internship-id })) ERR-ALREADY-CERTIFIED)
    (let ((certificate-id (var-get next-certificate-id))
          (company (unwrap-panic company-info))
          (internship (unwrap-panic internship-info))
          (verification (hash-certificate student-id internship-id performance-score)))
      (asserts! (is-eq (get company-id company) (get company-id internship)) ERR-UNAUTHORIZED)
      (begin
        (map-set certificates
          { certificate-id: certificate-id }
          {
            student-id: student-id,
            internship-id: internship-id,
            company-id: (get company-id company),
            performance-score: performance-score,
            completion-date: stacks-block-height,
            duration-completed: (get duration internship),
            issued-by: tx-sender,
            verification-hash: verification
          }
        )
        (map-set student-certificates
          { student-id: student-id, internship-id: internship-id }
          { certificate-id: certificate-id }
        )
        (unwrap-panic (update-certificate-count student-id))
        (var-set next-certificate-id (+ certificate-id u1))
        (ok certificate-id)
      )
    )
  )
)

(define-private (hash-certificate (student-id uint) (internship-id uint) (performance-score uint))
  (sha256 (concat (concat (unwrap-panic (to-consensus-buff? student-id)) 
                          (unwrap-panic (to-consensus-buff? internship-id)))
                  (unwrap-panic (to-consensus-buff? performance-score))))
)

(define-private (update-certificate-count (student-id uint))
  (let ((current (default-to { count: u0 } (map-get? certificate-count { student-id: student-id }))))
    (map-set certificate-count
      { student-id: student-id }
      { count: (+ (get count current) u1) }
    )
    (ok true)
  )
)

(define-read-only (get-certificate (certificate-id uint))
  (map-get? certificates { certificate-id: certificate-id })
)

(define-read-only (get-student-certificate (student-id uint) (internship-id uint))
  (map-get? student-certificates { student-id: student-id, internship-id: internship-id })
)

(define-read-only (get-total-certificates (student-id uint))
  (get count (default-to { count: u0 } (map-get? certificate-count { student-id: student-id })))
)

(define-read-only (verify-certificate (certificate-id uint) (expected-hash (buff 32)))
  (match (map-get? certificates { certificate-id: certificate-id })
    certificate (ok (is-eq (get verification-hash certificate) expected-hash))
    (ok false)
  )
)
