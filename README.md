# 🎯 Decentralized Intern Matching System

A blockchain-based platform for connecting students with internship opportunities through merit-based matching on the Stacks blockchain.

## 🌟 Overview

This smart contract enables students to apply for internships in a decentralized manner, where companies can post opportunities and match with qualified candidates based on tokenized merit scores and academic performance.

## ✨ Features

- 👨‍🎓 **Student Registration**: Students can register with their skills, GPA, and merit scores
- 🏢 **Company Registration**: Companies can register and post internship opportunities
- 📝 **Internship Applications**: Students can apply for posted internships
- 🎯 **Merit-Based Matching**: Companies match students based on merit scores and GPA requirements
- 🏆 **Merit Rewards**: Students earn merit points for successful matches
- 🔍 **Transparent Tracking**: All applications and matches are recorded on-chain

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Run `clarinet console` to interact with the contract

## 📋 Usage Instructions

### For Students 👨‍🎓

#### Register as a Student
```clarity
(contract-call? .Decentralized-Intern-Matching-System register-student "John Doe" "JavaScript, React, Node.js" u350)
```
- `name`: Your full name (max 64 characters)
- `skills`: Your technical skills (max 256 characters)
- `gpa`: Your GPA * 100 (e.g., 3.5 GPA = u350)

#### Apply for an Internship
```clarity
(contract-call? .Decentralized-Intern-Matching-System apply-for-internship u1)
```
- `internship-id`: The ID of the internship you want to apply for

### For Companies 🏢

#### Register as a Company
```clarity
(contract-call? .Decentralized-Intern-Matching-System register-company "Tech Corp Inc")
```
- `name`: Company name (max 64 characters)

#### Post an Internship
```clarity
(contract-call? .Decentralized-Intern-Matching-System post-internship "Frontend Developer Intern" "React, JavaScript, HTML/CSS" u50 u300 u12)
```
- `title`: Internship title (max 64 characters)
- `requirements`: Required skills (max 256 characters)
- `min-merit-score`: Minimum merit score required
- `min-gpa`: Minimum GPA required (* 100)
- `duration`: Duration in weeks

#### Match a Student to an Internship
```clarity
(contract-call? .Decentralized-Intern-Matching-System match-internship u1 u1)
```
- `internship-id`: The internship ID
- `student-id`: The student ID to match

### For Contract Owner 👑

#### Award Merit Points
```clarity
(contract-call? .Decentralized-Intern-Matching-System award-merit u1 u25)
```
- `student-id`: The student to award points to
- `points`: Number of merit points to award

## 🔍 Query Functions

### Get Student Information
```clarity
(contract-call? .Decentralized-Intern-Matching-System get-student u1)
```

### Get Company Information
```clarity
(contract-call? .Decentralized-Intern-Matching-System get-company u1)
```

### Get Internship Details
```clarity
(contract-call? .Decentralized-Intern-Matching-System get-internship u1)
```

### Get Application Status
```clarity
(contract-call? .Decentralized-Intern-Matching-System get-application u1)
```

### Get Student by Wallet
```clarity
(contract-call? .Decentralized-Intern-Matching-System get-student-by-wallet 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Get Company by Wallet
```clarity
(contract-call? .Decentralized-Intern-Matching-System get-company-by-wallet 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Get Contract Statistics
```clarity
(contract-call? .Decentralized-Intern-Matching-System get-contract-info)
```

## 🏗️ Contract Architecture

### Data Structures

- **Students**: Stores student profiles with skills, GPA, and merit scores
- **Companies**: Stores company information and registration status
- **Internships**: Stores internship postings with requirements and matching status
- **Applications**: Tracks all student applications with timestamps

### Merit System 🏆

Students earn merit points through:
- Successful internship matches (+10 points)
- Additional awards from contract owner
- Merit scores determine eligibility for higher-tier internships

## 🔐 Security Features

- Wallet-based authentication
- Owner-only merit award functions
- Duplicate registration prevention
- Input validation and sanitization
- State consistency checks

## 📊 Error Codes

- `u100`: Owner-only function
- `u101`: Entity not found
- `u102`: Entity already exists
- `u103`: Unauthorized access
- `u104`: Invalid parameters
- `u105`: Already matched
- `u106`: Insufficient merit/GPA

## 🧪 Testing

Run the test suite with:
```bash
clarinet test
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🔗 Resources

- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Documentation](https://github.com/hirosystems/clarinet)
- [Stacks Blockchain](https://stacks.co/)

---

Built with ❤️ on the Stacks blockchain
