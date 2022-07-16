var express = require('express');
var app = express();
var bodyParser = require('body-parser');
var cors = require('cors');
var moment = require('moment');

var db = require('./db');

app.use(bodyParser.json());
app.use(cors());

const port = 8000;

app.listen(port, function (err, res) {
    if (err) {
        console.log(err);
    }
    else {
        console.log("server is running on ", port);
    }
});

app.all('*', (req, res, next) => {
    // Pass to next layer of middleware
    next();
});

app.post('/loan_calc', (req, res, next) => {
    /*Define response structure*/
    var response = {
        status: false,
        message: "Invalid inputs",
        data: null,
        error: null
    };
    var validator = true;

    if (!req.body.city || !req.body.creditScore || !req.body.loanAmount || !req.body.name || !req.body.dob) {
        response.error = 'Invalid Inputs';
        validator *= false;
    }

    if (validator) {
        if (!/^[a-zA-Z ]*$/.test(req.body.name)) {
            response.error = {
                name: "Invalid input for name"
            }
            validator *= false;
        }

        if (!moment(req.body.dob).isValid()) {
            response.error = {
                name: "Invalid date format for date of birth. Enter in YYYY-MM-DD"
            }
            validator *= false;
        }
    }

    if (!validator) {
        response.message = 'Pls check the entered inputs';
        res.status(400).json(response);
    } else {

        var inputs = [
            db.escape(req.body.name),
            db.escape(req.body.dob),
            db.escape(req.body.city),
            db.escape(req.body.creditScore),
            db.escape(req.body.loanAmount)
        ]
        // prepare call statement with comma separated inputs to proc
        var proc = 'call proc_dloan_request_calculator(' + inputs.join(',') + ')';
        db.query(proc, (err, results) => {
            if (!err && results && results[0] && results[0][0] && (results[0][0]._error || results[0][0].Code)) {
                response.status = false;
                response.message = results[0][0]._error || results[0][0].Code;
                res.status(200).json(response);
            } else if (!err && results[0] && results[0][0] && results[1] && results[1][0]) {
                response.status = true;
                response.message = results[0][0].message;
                response.data = {
                    successMessage: results[0][0].message,
                    emiSchedules: results[1]
                }
                res.status(200).json(response);
            }
        })
    }
});