Once the project is cloned into local system following are the Steps to set up the project to run.

Database set up
1. Install MySQL server
2. Execute the banking_loan_lending_system.sql file from CLI or from mysql workbench.
   Database will be created, tables and procedures will be created.


NodeJS Set up
1. Install NodeJS
2. Navigate inside the project and Run "npm install" to install dependencies
3. Open db.js file and give your machine mysql "db_user" and "db_pass"
4. Run "npm start" on the terminal. Node Service will be running on port 8000
5. Below is the end point created. Using PostMan API can be verified with required inputs.

End point : http://localhost:8000/loan_calc
Method: POST
Content-type : application/json
Sample Request Parameters:

{
  "name": "Arun Gavimath",
  "dob": "1993-05-27",
  "city": "Hubli",
  "creditScore": 850,
  "loanAmount": 100000
}


6. Pls email at arungavimath73@gmail.com for any challenges.