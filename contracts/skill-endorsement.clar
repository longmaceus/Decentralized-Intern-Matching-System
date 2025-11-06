(define-constant ERR-NOT-FOUND (err u501))
(define-constant ERR-UNAUTHORIZED (err u502))
(define-constant ERR-INVALID-LEVEL (err u503))
(define-constant ERR-ALREADY-ENDORSED (err u504))
(define-constant ERR-NO-CERTIFICATE (err u505))

(define-data-var next-endorsement-id uint u1)

(define-map skill-endorsements
  { endorsement-id: uint }
  {
    student-id: uint,
    company-id: uint,
    skill-name: (string-ascii 64),
    proficiency-level: uint,
    internship-id: uint,
    endorsed-at: uint,
    endorser: principal
  }
)

(define-map student-skill-index
  { student-id: uint, skill-name: (string-ascii 64) }
  {
    total-endorsements: uint,
    average-level: uint,
    highest-level: uint
  }
)

(define-map company-student-endorsement
  { company-id: uint, student-id: uint, skill-name: (string-ascii 64) }
  { endorsed: bool }
)

(define-map endorsement-count
  { student-id: uint }
  { total: uint }
)

(define-public (endorse-skill (student-id uint) (internship-id uint) (skill-name (string-ascii 64)) (proficiency-level uint))
  (let ((company-info (contract-call? .Decentralized-Intern-Matching-System get-company-by-wallet tx-sender))
        (certificate-info (contract-call? .certificate-system get-student-certificate student-id internship-id))
        (student-info (contract-call? .Decentralized-Intern-Matching-System get-student student-id)))
    (asserts! (is-some company-info) ERR-UNAUTHORIZED)
    (asserts! (is-some student-info) ERR-NOT-FOUND)
    (asserts! (is-some certificate-info) ERR-NO-CERTIFICATE)
    (asserts! (and (> proficiency-level u0) (<= proficiency-level u100)) ERR-INVALID-LEVEL)
    (asserts! (> (len skill-name) u0) ERR-INVALID-LEVEL)
    (let ((company-id (get company-id (unwrap-panic company-info)))
          (already-endorsed (default-to { endorsed: false } 
            (map-get? company-student-endorsement { company-id: company-id, student-id: student-id, skill-name: skill-name }))))
      (asserts! (not (get endorsed already-endorsed)) ERR-ALREADY-ENDORSED)
      (let ((endorsement-id (var-get next-endorsement-id)))
        (map-set skill-endorsements
          { endorsement-id: endorsement-id }
          {
            student-id: student-id,
            company-id: company-id,
            skill-name: skill-name,
            proficiency-level: proficiency-level,
            internship-id: internship-id,
            endorsed-at: stacks-block-height,
            endorser: tx-sender
          }
        )
        (map-set company-student-endorsement
          { company-id: company-id, student-id: student-id, skill-name: skill-name }
          { endorsed: true }
        )
        (unwrap-panic (update-skill-metrics student-id skill-name proficiency-level))
        (var-set next-endorsement-id (+ endorsement-id u1))
        (ok endorsement-id)
      )
    )
  )
)

(define-private (update-skill-metrics (student-id uint) (skill-name (string-ascii 64)) (level uint))
  (let ((current-metrics (default-to 
          { total-endorsements: u0, average-level: u0, highest-level: u0 }
          (map-get? student-skill-index { student-id: student-id, skill-name: skill-name })))
        (total-count (default-to { total: u0 } (map-get? endorsement-count { student-id: student-id }))))
    (let ((new-count (+ (get total-endorsements current-metrics) u1))
          (new-avg (/ (+ (* (get average-level current-metrics) (get total-endorsements current-metrics)) level) new-count)))
      (map-set student-skill-index
        { student-id: student-id, skill-name: skill-name }
        {
          total-endorsements: new-count,
          average-level: new-avg,
          highest-level: (if (> level (get highest-level current-metrics)) level (get highest-level current-metrics))
        }
      )
      (map-set endorsement-count
        { student-id: student-id }
        { total: (+ (get total total-count) u1) }
      )
      (ok true)
    )
  )
)

(define-read-only (get-endorsement (endorsement-id uint))
  (map-get? skill-endorsements { endorsement-id: endorsement-id })
)

(define-read-only (get-skill-summary (student-id uint) (skill-name (string-ascii 64)))
  (map-get? student-skill-index { student-id: student-id, skill-name: skill-name })
)

(define-read-only (get-total-endorsements (student-id uint))
  (get total (default-to { total: u0 } (map-get? endorsement-count { student-id: student-id })))
)

(define-read-only (is-skill-endorsed (company-id uint) (student-id uint) (skill-name (string-ascii 64)))
  (get endorsed (default-to { endorsed: false } 
    (map-get? company-student-endorsement { company-id: company-id, student-id: student-id, skill-name: skill-name })))
)
