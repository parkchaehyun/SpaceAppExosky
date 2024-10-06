const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const port = 3000; // EC2의 실제 사용 포트는 80 또는 443으로 변경 가능

// JSON 파일을 반환하는 API
app.get('/planet', (req, res) => {
    const { name, lat, lon } = req.query;

    if (!name || !lat || !lon) {
        return res.status(400).json({ error: 'Missing parameters: name, lat, lon' });
    }

    const filePath = path.join(__dirname, 'data', name, `${lat}_${lon}.json`);

    // 해당 좌표에 맞는 파일이 있는지 확인
    fs.access(filePath, fs.constants.F_OK, (err) => {
        if (err) {
            return res.status(404).json({ error: 'File not found for the given coordinates' });
        }

        // 파일을 읽어 클라이언트에 전달
        fs.readFile(filePath, 'utf8', (err, data) => {
            if (err) {
                return res.status(500).json({ error: 'Error reading file' });
            }

            res.json(JSON.parse(data));
        });
    });
});

// 서버 시작
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});
