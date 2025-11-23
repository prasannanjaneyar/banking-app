const express = require('express');
const path = require('path');
const app = express();
const PORT = 8080;

app.use(express.static('public'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Mock user data
const users = {
    '5439090': {
        customerId: '5439090',
        password: 'Passw0rd!!',
        name: 'John Doe',
        accountNumber: '1234567890',
        balance: 125000.00,
        accountType: 'Savings Account'
    }
};

// Mock loan data
const loanTypes = {
    personal: {
        name: 'Personal Loan',
        interestRate: '10.5%',
        maxAmount: '₹15,00,000',
        tenure: 'Up to 5 years'
    },
    mortgage: {
        name: 'Mortgage Loan',
        interestRate: '8.5%',
        maxAmount: '₹75,00,000',
        tenure: 'Up to 30 years'
    },
    car: {
        name: 'Car Loan',
        interestRate: '9.0%',
        maxAmount: '₹20,00,000',
        tenure: 'Up to 7 years'
    }
};

// Login endpoint
app.post('/login', (req, res) => {
    const { customerId, password } = req.body;
    
    if (users[customerId] && users[customerId].password === password) {
        res.json({ 
            success: true, 
            redirect: '/home.html',
            user: {
                name: users[customerId].name,
                accountNumber: users[customerId].accountNumber
            }
        });
    } else {
        res.json({ 
            success: false, 
            message: 'Invalid Customer ID or Password' 
        });
    }
});

// Get account details
app.get('/api/account', (req, res) => {
    const user = users['5439090'];
    res.json({
        name: user.name,
        accountNumber: user.accountNumber,
        balance: user.balance,
        accountType: user.accountType
    });
});

// Get loan details
app.get('/api/loans', (req, res) => {
    res.json(loanTypes);
});

// Transfer money - Same Bank
app.post('/api/transfer/same-bank', (req, res) => {
    const { toAccount, amount, remarks } = req.body;
    
    console.log(`Same Bank Transfer: ₹${amount} to ${toAccount}`);
    
    res.json({
        success: true,
        message: 'Transfer successful',
        transactionId: 'TXN' + Date.now(),
        amount: amount,
        toAccount: toAccount,
        type: 'Same Bank Transfer'
    });
});

// Transfer money - Other Bank
app.post('/api/transfer/other-bank', (req, res) => {
    const { toAccount, ifsc, amount, remarks } = req.body;
    
    console.log(`Other Bank Transfer: ₹${amount} to ${toAccount} (${ifsc})`);
    
    res.json({
        success: true,
        message: 'Transfer initiated (NEFT/RTGS)',
        transactionId: 'TXN' + Date.now(),
        amount: amount,
        toAccount: toAccount,
        ifsc: ifsc,
        type: 'Other Bank Transfer'
    });
});

// Apply for loan
app.post('/api/loan/apply', (req, res) => {
    const { loanType, amount, tenure } = req.body;
    
    console.log(`Loan Application: ${loanType} - ₹${amount} for ${tenure} months`);
    
    res.json({
        success: true,
        message: 'Loan application submitted successfully',
        applicationId: 'LOAN' + Date.now(),
        loanType: loanType,
        amount: amount,
        status: 'Under Review'
    });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Banking app running on port ${PORT}`);
    console.log(`Health check available at http://localhost:${PORT}/health`);
});
