(define-constant ERR-NOT-FOUND (err u201))
(define-constant ERR-UNAUTHORIZED (err u202))
(define-constant ERR-INVALID-BADGE (err u203))

(define-data-var next-badge-id uint u1)

(define-map student-reputation
  { student-id: uint }
  {
    applications-count: uint,
    matches-count: uint,
    response-time-avg: uint,
    last-activity: uint,
    reputation-score: uint
  }
)

(define-map reputation-badges
  { badge-id: uint }
  {
    student-id: uint,
    badge-type: (string-ascii 32),
    earned-at: uint,
    criteria-met: (string-ascii 128)
  }
)

(define-map student-badge-count
  { student-id: uint }
  { badge-count: uint }
)

(define-public (initialize-reputation (student-id uint))
  (begin
    (asserts! (is-some (contract-call? .Decentralized-Intern-Matching-System get-student student-id)) ERR-NOT-FOUND)
    (map-set student-reputation
      { student-id: student-id }
      {
        applications-count: u0,
        matches-count: u0,
        response-time-avg: u0,
        last-activity: stacks-block-height,
        reputation-score: u100
      }
    )
    (map-set student-badge-count { student-id: student-id } { badge-count: u0 })
    (ok true)
  )
)

(define-public (update-application-activity (student-id uint))
  (let ((reputation-data (default-to 
    { applications-count: u0, matches-count: u0, response-time-avg: u0, last-activity: u0, reputation-score: u100 }
    (map-get? student-reputation { student-id: student-id }))))
    (map-set student-reputation
      { student-id: student-id }
      (merge reputation-data {
        applications-count: (+ (get applications-count reputation-data) u1),
        last-activity: stacks-block-height,
        reputation-score: (if (> (+ (get reputation-score reputation-data) u5) u1000) u1000 (+ (get reputation-score reputation-data) u5))
      })
    )
    (unwrap-panic (check-and-award-badges student-id))
    (ok true)
  )
)

(define-public (update-match-activity (student-id uint))
  (let ((reputation-data (unwrap! (map-get? student-reputation { student-id: student-id }) ERR-NOT-FOUND)))
    (map-set student-reputation
      { student-id: student-id }
      (merge reputation-data {
        matches-count: (+ (get matches-count reputation-data) u1),
        reputation-score: (if (> (+ (get reputation-score reputation-data) u25) u1000) u1000 (+ (get reputation-score reputation-data) u25))
      })
    )
    (ok true)
  )
)

(define-private (check-and-award-badges (student-id uint))
  (let ((reputation-data (unwrap-panic (map-get? student-reputation { student-id: student-id }))))
    (begin
      (if (>= (get applications-count reputation-data) u5)
        (begin (unwrap-panic (award-badge student-id "active-applicant" "Applied to 5+ internships")) true)
        false)
      (if (>= (get matches-count reputation-data) u1)
        (begin (unwrap-panic (award-badge student-id "first-match" "Successfully matched")) true)
        false)
      (if (>= (get reputation-score reputation-data) u500)
        (begin (unwrap-panic (award-badge student-id "high-reputation" "Achieved 500+ reputation")) true)
        false)
      (ok true)
    )
  )
)

(define-private (award-badge (student-id uint) (badge-type (string-ascii 32)) (criteria (string-ascii 128)))
  (let ((badge-id (var-get next-badge-id))
        (current-count (default-to { badge-count: u0 } (map-get? student-badge-count { student-id: student-id }))))
    (map-set reputation-badges
      { badge-id: badge-id }
      {
        student-id: student-id,
        badge-type: badge-type,
        earned-at: stacks-block-height,
        criteria-met: criteria
      }
    )
    (map-set student-badge-count
      { student-id: student-id }
      { badge-count: (+ (get badge-count current-count) u1) }
    )
    (var-set next-badge-id (+ badge-id u1))
    (ok badge-id)
  )
)

(define-read-only (get-reputation (student-id uint))
  (map-get? student-reputation { student-id: student-id })
)

(define-read-only (get-badge (badge-id uint))
  (map-get? reputation-badges { badge-id: badge-id })
)

(define-read-only (get-student-badges (student-id uint))
  (get badge-count (default-to { badge-count: u0 } (map-get? student-badge-count { student-id: student-id })))
)

(define-read-only (get-badge-by-type (student-id uint) (badge-type (string-ascii 32)))
  (let ((badge-1 (map-get? reputation-badges { badge-id: u1 }))
        (badge-2 (map-get? reputation-badges { badge-id: u2 }))
        (badge-3 (map-get? reputation-badges { badge-id: u3 })))
    (if (and (is-some badge-1)
             (is-eq (get student-id (unwrap-panic badge-1)) student-id)
             (is-eq (get badge-type (unwrap-panic badge-1)) badge-type))
      (some u1)
      (if (and (is-some badge-2)
               (is-eq (get student-id (unwrap-panic badge-2)) student-id)
               (is-eq (get badge-type (unwrap-panic badge-2)) badge-type))
        (some u2)
        (if (and (is-some badge-3)
                 (is-eq (get student-id (unwrap-panic badge-3)) student-id)
                 (is-eq (get badge-type (unwrap-panic badge-3)) badge-type))
          (some u3)
          none
        )
      )
    )
  )
)