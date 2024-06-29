#!/bin/bash

# Update and install dependencies
sudo apt update
sudo apt install -y curl

# Install Node.js
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt install -y nodejs

# Create project directory
mkdir -p ~/factory-management
cd ~/factory-management

# Create package.json
cat <<EOL > package.json
{
  "name": "factory-management",
  "version": "1.0.0",
  "description": "Factory management system",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "body-parser": "^1.19.0",
    "express": "^4.17.1",
    "sqlite3": "^5.0.0"
  },
  "author": "",
  "license": "ISC"
}
EOL

# Install Node.js dependencies
npm install

# Create server.js
cat <<EOL > server.js
const express = require('express');
const bodyParser = require('body-parser');
const sqlite3 = require('sqlite3').verbose();

const app = express();
const db = new sqlite3.Database(':memory:');

app.use(bodyParser.json());
app.use(express.static('public'));

db.serialize(() => {
  db.run(\`
    CREATE TABLE records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT,
      workerCost REAL,
      machineCost REAL,
      materialCost REAL,
      produced TEXT,
      productionAmount REAL,
      productionReason TEXT,
      materialUsage TEXT,
      materialPrices TEXT
    )
  \`);
});

app.post('/add-record', (req, res) => {
  const {
    date,
    workerCost,
    machineCost,
    materialCost,
    produced,
    productionAmount,
    productionReason,
    materialUsage,
    materialPrices
  } = req.body;

  db.run(\`
    INSERT INTO records (date, workerCost, machineCost, materialCost, produced, productionAmount, productionReason, materialUsage, materialPrices)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  \`, [date, workerCost, machineCost, materialCost, produced, productionAmount, productionReason, JSON.stringify(materialUsage), JSON.stringify(materialPrices)], function (err) {
    if (err) {
      return res.status(500).send('Error storing record');
    }
    res.status(200).send('Record added successfully');
  });
});

app.get('/records', (req, res) => {
  db.all('SELECT * FROM records', [], (err, rows) => {
    if (err) {
      return res.status(500).send('Error retrieving records');
    }
    res.json(rows);
  });
});

app.listen(3000, () => {
  console.log('Server is running on port 3000');
});
EOL

# Create public directory and HTML/CSS files
mkdir -p public

cat <<EOL > public/index.html
<!DOCTYPE html>
<html lang="fa">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>مدیریت کارخانه آبمیوه</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <h1>مدیریت کارخانه آبمیوه</h1>
        <form id="factoryForm">
            <label for="date">تاریخ</label>
            <input type="date" id="date" required>

            <label for="workerCost">حقوق کارگران (ریال)</label>
            <input type="number" id="workerCost" required>

            <label for="machineCost">سرمایه ماشین آلات نصب شده (ریال)</label>
            <input type="number" id="machineCost" required>

            <label for="materialCost">سرمایه در گردش مواد اولیه (ریال)</label>
            <input type="number" id="materialCost" required>

            <label for="produced">آیا تولید داشتید؟</label>
            <select id="produced" required>
                <option value="yes">بله</option>
                <option value="no">خیر</option>
            </select>

            <div id="productionDetails" style="display: none;">
                <label for="productionAmount">مقدار تولید (لیتر)</label>
                <input type="number" id="productionAmount">

                <label for="productionReason">دلیل عدم تولید</label>
                <select id="productionReason">
                    <option value="none">انتخاب دلیل</option>
                    <option value="مواد اولیه">نبود مواد اولیه</option>
                    <option value="خرابی ماشین آلات">خرابی ماشین آلات</option>
                    <option value="نبود برق">نبود برق</option>
                    <option value="نبود نیروی انسانی">نبود نیروی انسانی</option>
                </select>
            </div>

            <label for="materialUsage">مقدار مصرف مواد اولیه (JSON)</label>
            <textarea id="materialUsage" placeholder='مثال: {"شکر": 100, "کنسانتره": 50}' required></textarea>

            <label for="materialPrices">قیمت مواد اولیه (JSON)</label>
            <textarea id="materialPrices" placeholder='مثال: {"شکر": 2000, "کنسانتره": 5000}' required></textarea>

            <button type="button" onclick="addRecord()">ثبت اطلاعات</button>
        </form>
        <div id="result" class="result"></div>
    </div>

    <script>
        function addRecord() {
            const date = document.getElementById('date').value;
            const workerCost = parseFloat(document.getElementById('workerCost').value);
            const machineCost = parseFloat(document.getElementById('machineCost').value);
            const materialCost = parseFloat(document.getElementById('materialCost').value);
            const produced = document.getElementById('produced').value;
            let productionAmount = 0;
            let productionReason = '';

            if (produced === 'yes') {
                productionAmount = parseFloat(document.getElementById('productionAmount').value);
            } else {
                productionReason = document.getElementById('productionReason').value;
            }

            const materialUsage = JSON.parse(document.getElementById('materialUsage').value);
            const materialPrices = JSON.parse(document.getElementById('materialPrices').value);

            const record = {
                date,
                workerCost,
                machineCost,
                materialCost,
                produced,
                productionAmount,
                productionReason,
                materialUsage,
                materialPrices
            };

            fetch('/add-record', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(record)
            }).then(response => {
                if (response.ok) {
                    document.getElementById('result').innerText = 'اطلاعات با موفقیت ثبت شد';
                    document.getElementById('factoryForm').reset();
                    document.getElementById('productionDetails').style.display = 'none';
                } else {
                    document.getElementById('result').innerText = 'خطا در ثبت اطلاعات';
                }
            });
        }

        document.getElementById('produced').addEventListener('change', function() {
            const productionDetails = document.getElementById('productionDetails');
            if (this.value === 'yes') {
                productionDetails.style.display = 'block';
                document.getElementById('productionReason').value = 'none';
                document.getElementById('productionAmount').required = true;
                document.getElementById('productionReason').required = false;
            } else {
                productionDetails.style.display = 'block';
                document.getElementById('productionAmount').value = '';
                document.getElementById('productionAmount').required = false;
                document.getElementById('productionReason').required = true;
            }
        });
    </script>
</body>
</html>
EOL

cat <<EOL > public/style.css
body {
    font-family: Arial, sans-serif;
    margin: 20px;
    direction: rtl;
}
.container {
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
    border: 1px solid #ccc;
    border-radius: 10px;
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
}
label {
    display: block;
    margin: 10px 0 5px;
}
input, select, textarea {
    width: calc(100% - 24px);
    padding: 8px;
    margin-bottom: 10px;
    border: 1px solid #ccc;
    border-radius: 5px;
}
button {
    padding: 10px 20px;
    background-color: #28a745;
    color: white;
    border: none;
    border-radius: 5px;
    cursor: pointer;
}
button:hover {
    background-color: #218838;
}
.result {
    margin-top: 20px;
    padding: 10px;
    background-color: #f8f9fa;
    border: 1px solid #ccc;
    border-radius: 5px;
}
EOL

# Start the server
npm start
