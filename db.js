var mysql = require('mysql'),
    db_server = "localhost",    // DB IP or Domain
    db_port = 3306,             // Default mysql tcp port
    db_collection = "banking_system"    //  DB Name
db_user = 'root',            // DB User Creds
    db_pass = 'pass123';


var pool = mysql.createPool({
    host: db_server,
    port: db_port,
    database: db_collection,
    user: db_user,
    password: db_pass,
    multipleStatements: true,
    waitForConnection: true,
    queueLimit: 0,
    dateStrings: true,
    charset: "utf8mb4",
    ssl: true
});

module.exports = pool;