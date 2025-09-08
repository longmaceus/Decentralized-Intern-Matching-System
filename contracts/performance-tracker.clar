(define-constant ERR-NOT-FOUND (err u301))
(define-constant ERR-UNAUTHORIZED (err u302))
(define-constant ERR-ALREADY-COMPLETED (err u303))
(define-constant ERR-INVALID-PARAMS (err u304))

(define-data-var next-milestone-id uint u1)

(define-map internship-milestones
  { internship-id: uint }
  {
    milestone-count: uint,
    completed-count: uint,
    performance-score: uint,
    last-updated: uint
  }
)

(define-map milestones
  { milestone-id: uint }
  {
    internship-id: uint,
    description: (string-ascii 128),
    points: uint,
    completed: bool,
    completed-by: (optional uint),
    completed-at: (optional uint)
  }
)

(define-map student-performance
  { student-id: uint, internship-id: uint }
  {
    total-milestones: uint,
    completed-milestones: uint,
    performance-rating: uint,
    efficiency-score: uint
  }
)

(define-public (setup-milestones (internship-id uint) (descriptions (list 3 (string-ascii 128))) (points (list 3 uint)))
  (let ((company-info (contract-call? .Decentralized-Intern-Matching-System get-company-by-wallet tx-sender))
        (internship-info (contract-call? .Decentralized-Intern-Matching-System get-internship internship-id)))
    (asserts! (is-some company-info) ERR-UNAUTHORIZED)
    (asserts! (is-some internship-info) ERR-NOT-FOUND)
    (asserts! (is-eq (len descriptions) (len points)) ERR-INVALID-PARAMS)
    (let ((company-id (get company-id (unwrap-panic company-info)))
          (internship (unwrap-panic internship-info)))
      (asserts! (is-eq company-id (get company-id internship)) ERR-UNAUTHORIZED)
      (map-set internship-milestones
        { internship-id: internship-id }
        {
          milestone-count: (len descriptions),
          completed-count: u0,
          performance-score: u0,
          last-updated: stacks-block-height
        }
      )
      (fold create-milestone descriptions { internship-id: internship-id, points: points, index: u0 })
      (ok true)
    )
  )
)

(define-private (create-milestone (description (string-ascii 128)) (acc { internship-id: uint, points: (list 3 uint), index: uint }))
  (let ((milestone-id (var-get next-milestone-id))
        (point-value (unwrap-panic (element-at (get points acc) (get index acc)))))
    (map-set milestones
      { milestone-id: milestone-id }
      {
        internship-id: (get internship-id acc),
        description: description,
        points: point-value,
        completed: false,
        completed-by: none,
        completed-at: none
      }
    )
    (var-set next-milestone-id (+ milestone-id u1))
    { internship-id: (get internship-id acc), points: (get points acc), index: (+ (get index acc) u1) }
  )
)

(define-public (complete-milestone (milestone-id uint) (student-id uint))
  (let ((milestone-info (map-get? milestones { milestone-id: milestone-id }))
        (student-info (contract-call? .Decentralized-Intern-Matching-System get-student student-id)))
    (asserts! (is-some milestone-info) ERR-NOT-FOUND)
    (asserts! (is-some student-info) ERR-NOT-FOUND)
    (let ((milestone (unwrap-panic milestone-info))
          (internship-id (get internship-id milestone)))
      (asserts! (not (get completed milestone)) ERR-ALREADY-COMPLETED)
      (asserts! (is-eq tx-sender (get wallet (unwrap-panic student-info))) ERR-UNAUTHORIZED)
      (map-set milestones
        { milestone-id: milestone-id }
        (merge milestone {
          completed: true,
          completed-by: (some student-id),
          completed-at: (some stacks-block-height)
        })
      )
      (unwrap-panic (update-performance-metrics internship-id student-id (get points milestone)))
      (ok true)
    )
  )
)

(define-private (update-performance-metrics (internship-id uint) (student-id uint) (points uint))
  (let ((milestone-data (default-to 
          { milestone-count: u0, completed-count: u0, performance-score: u0, last-updated: u0 }
          (map-get? internship-milestones { internship-id: internship-id })))
        (performance-data (default-to
          { total-milestones: u0, completed-milestones: u0, performance-rating: u0, efficiency-score: u0 }
          (map-get? student-performance { student-id: student-id, internship-id: internship-id }))))
    (map-set internship-milestones
      { internship-id: internship-id }
      (merge milestone-data {
        completed-count: (+ (get completed-count milestone-data) u1),
        performance-score: (+ (get performance-score milestone-data) points),
        last-updated: stacks-block-height
      })
    )
    (map-set student-performance
      { student-id: student-id, internship-id: internship-id }
      (merge performance-data {
        total-milestones: (get milestone-count milestone-data),
        completed-milestones: (+ (get completed-milestones performance-data) u1),
        performance-rating: (+ (get performance-rating performance-data) points),
        efficiency-score: (if (> (get milestone-count milestone-data) u0) 
                            (/ (* (+ (get completed-milestones performance-data) u1) u100) (get milestone-count milestone-data))
                            u0)
      })
    )
    (ok true)
  )
)

(define-read-only (get-internship-progress (internship-id uint))
  (map-get? internship-milestones { internship-id: internship-id })
)

(define-read-only (get-student-performance (student-id uint) (internship-id uint))
  (map-get? student-performance { student-id: student-id, internship-id: internship-id })
)

(define-read-only (get-milestone (milestone-id uint))
  (map-get? milestones { milestone-id: milestone-id })
)
