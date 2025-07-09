(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-UNAUTHORIZED (err u103))
(define-constant ERR-INVALID-PARAMS (err u104))
(define-constant ERR-ALREADY-MATCHED (err u105))
(define-constant ERR-INSUFFICIENT-MERIT (err u106))

(define-data-var next-student-id uint u1)
(define-data-var next-company-id uint u1)
(define-data-var next-internship-id uint u1)
(define-data-var next-application-id uint u1)

(define-map students
  { student-id: uint }
  {
    wallet: principal,
    name: (string-ascii 64),
    skills: (string-ascii 256),
    merit-score: uint,
    gpa: uint,
    active: bool
  }
)

(define-map companies
  { company-id: uint }
  {
    wallet: principal,
    name: (string-ascii 64),
    active: bool
  }
)

(define-map internships
  { internship-id: uint }
  {
    company-id: uint,
    title: (string-ascii 64),
    requirements: (string-ascii 256),
    min-merit-score: uint,
    min-gpa: uint,
    duration: uint,
    active: bool,
    matched-student: (optional uint)
  }
)

(define-map applications
  { application-id: uint }
  {
    student-id: uint,
    internship-id: uint,
    timestamp: uint,
    status: (string-ascii 16)
  }
)

(define-map student-wallets { wallet: principal } { student-id: uint })
(define-map company-wallets { wallet: principal } { company-id: uint })

(define-public (register-student (name (string-ascii 64)) (skills (string-ascii 256)) (gpa uint))
  (let ((student-id (var-get next-student-id)))
    (asserts! (is-none (map-get? student-wallets { wallet: tx-sender })) ERR-ALREADY-EXISTS)
    (asserts! (> (len name) u0) ERR-INVALID-PARAMS)
    (asserts! (<= gpa u400) ERR-INVALID-PARAMS)
    (map-set students
      { student-id: student-id }
      {
        wallet: tx-sender,
        name: name,
        skills: skills,
        merit-score: u0,
        gpa: gpa,
        active: true
      }
    )
    (map-set student-wallets { wallet: tx-sender } { student-id: student-id })
    (var-set next-student-id (+ student-id u1))
    (ok student-id)
  )
)

(define-public (register-company (name (string-ascii 64)))
  (let ((company-id (var-get next-company-id)))
    (asserts! (is-none (map-get? company-wallets { wallet: tx-sender })) ERR-ALREADY-EXISTS)
    (asserts! (> (len name) u0) ERR-INVALID-PARAMS)
    (map-set companies
      { company-id: company-id }
      {
        wallet: tx-sender,
        name: name,
        active: true
      }
    )
    (map-set company-wallets { wallet: tx-sender } { company-id: company-id })
    (var-set next-company-id (+ company-id u1))
    (ok company-id)
  )
)

(define-public (post-internship (title (string-ascii 64)) (requirements (string-ascii 256)) (min-merit-score uint) (min-gpa uint) (duration uint))
  (let ((internship-id (var-get next-internship-id))
        (company-info (map-get? company-wallets { wallet: tx-sender })))
    (asserts! (is-some company-info) ERR-UNAUTHORIZED)
    (asserts! (> (len title) u0) ERR-INVALID-PARAMS)
    (asserts! (> duration u0) ERR-INVALID-PARAMS)
    (asserts! (<= min-gpa u400) ERR-INVALID-PARAMS)
    (map-set internships
      { internship-id: internship-id }
      {
        company-id: (get company-id (unwrap-panic company-info)),
        title: title,
        requirements: requirements,
        min-merit-score: min-merit-score,
        min-gpa: min-gpa,
        duration: duration,
        active: true,
        matched-student: none
      }
    )
    (var-set next-internship-id (+ internship-id u1))
    (ok internship-id)
  )
)

(define-public (apply-for-internship (internship-id uint))
  (let ((application-id (var-get next-application-id))
        (student-info (map-get? student-wallets { wallet: tx-sender }))
        (internship-info (map-get? internships { internship-id: internship-id })))
    (asserts! (is-some student-info) ERR-UNAUTHORIZED)
    (asserts! (is-some internship-info) ERR-NOT-FOUND)
    (let ((student-id (get student-id (unwrap-panic student-info)))
          (internship (unwrap-panic internship-info)))
      (asserts! (get active internship) ERR-NOT-FOUND)
      (asserts! (is-none (get matched-student internship)) ERR-ALREADY-MATCHED)
      (map-set applications
        { application-id: application-id }
        {
          student-id: student-id,
          internship-id: internship-id,
          timestamp: stacks-block-height,
          status: "pending"
        }
      )
      (var-set next-application-id (+ application-id u1))
      (ok application-id)
    )
  )
)

(define-public (match-internship (internship-id uint) (student-id uint))
  (let ((internship-info (map-get? internships { internship-id: internship-id }))
        (student-info (map-get? students { student-id: student-id }))
        (company-info (map-get? company-wallets { wallet: tx-sender })))
    (asserts! (is-some company-info) ERR-UNAUTHORIZED)
    (asserts! (is-some internship-info) ERR-NOT-FOUND)
    (asserts! (is-some student-info) ERR-NOT-FOUND)
    (let ((internship (unwrap-panic internship-info))
          (student (unwrap-panic student-info)))
      (asserts! (is-eq (get company-id (unwrap-panic company-info)) (get company-id internship)) ERR-UNAUTHORIZED)
      (asserts! (is-none (get matched-student internship)) ERR-ALREADY-MATCHED)
      (asserts! (>= (get merit-score student) (get min-merit-score internship)) ERR-INSUFFICIENT-MERIT)
      (asserts! (>= (get gpa student) (get min-gpa internship)) ERR-INSUFFICIENT-MERIT)
      (map-set internships
        { internship-id: internship-id }
        (merge internship { matched-student: (some student-id) })
      )
      (try! (award-merit student-id u10))
      (ok true)
    )
  )
)

(define-public (award-merit (student-id uint) (points uint))
  (let ((student-info (map-get? students { student-id: student-id })))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (is-some student-info) ERR-NOT-FOUND)
    (let ((student (unwrap-panic student-info)))
      (map-set students
        { student-id: student-id }
        (merge student { merit-score: (+ (get merit-score student) points) })
      )
      (ok true)
    )
  )
)

(define-read-only (get-student (student-id uint))
  (map-get? students { student-id: student-id })
)

(define-read-only (get-company (company-id uint))
  (map-get? companies { company-id: company-id })
)

(define-read-only (get-internship (internship-id uint))
  (map-get? internships { internship-id: internship-id })
)

(define-read-only (get-application (application-id uint))
  (map-get? applications { application-id: application-id })
)

(define-read-only (get-student-by-wallet (wallet principal))
  (map-get? student-wallets { wallet: wallet })
)

(define-read-only (get-company-by-wallet (wallet principal))
  (map-get? company-wallets { wallet: wallet })
)

(define-read-only (get-contract-info)
  {
    total-students: (- (var-get next-student-id) u1),
    total-companies: (- (var-get next-company-id) u1),
    total-internships: (- (var-get next-internship-id) u1),
    total-applications: (- (var-get next-application-id) u1),
    contract-owner: CONTRACT-OWNER
  }
)
