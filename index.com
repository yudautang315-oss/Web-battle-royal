<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mini Battle Royale - Free Fire Style</title>
    <style>
        body {
            margin: 0;
            background: #111;
            color: white;
            font-family: Arial, sans-serif;
            text-align: center;
            overflow: hidden;
        }
        canvas {
            background: #2b7a0b;
            display: block;
            margin: 20px auto;
            border: 4px solid #fff;
            box-shadow: 0 0 20px rgba(0,0,0,0.8);
        }
        #ui {
            font-size: 18px;
            font-weight: bold;
            margin-top: 10px;
        }
    </style>
</head>
<body>

    <h1>MINI BATTLE ROYALE</h1>
    <div id="ui">Gunakan Tombol W, A, S, D untuk Gerak | Klik Kiri untuk Menembak | Habisi Musuh!</div>
    <canvas id="gameCanvas" width="800" height="500"></canvas>

<script>
    const canvas = document.getElementById("gameCanvas");
    const ctx = canvas.getContext("2d");

    let player = {
        x: 400,
        y: 250,
        radius: 15,
        color: "#00ffcc",
        speed: 4,
        health: 100
    };

    let keys = {};
    let bullets = [];
    let enemies = [];
    let score = 0;
    let gameOver = false;

    // Tangkap input keyboard
    window.addEventListener("keydown", (e) => keys[e.key.toLowerCase()] = true);
    window.addEventListener("keyup", (e) => keys[e.key.toLowerCase()] = false);

    // Tangkap klik mouse untuk menembak
    window.addEventListener("click", (e) => {
        if (gameOver) return;
        const rect = canvas.getBoundingClientRect();
        const mouseX = e.clientX - rect.left;
        const mouseY = e.clientY - rect.top;

        const angle = Math.atan2(mouseY - player.y, mouseX - player.x);
        bullets.push({
            x: player.x,
            y: player.y,
            dx: Math.cos(angle) * 7,
            dy: Math.sin(angle) * 7,
            radius: 4
        });
    });

    // Munculkan musuh secara berkala
    setInterval(() => {
        if (gameOver) return;
        let edge = Math.floor(Math.random() * 4);
        let ex, ey;
        if (edge === 0) { ex = Math.random() * canvas.width; ey = -20; }
        else if (edge === 1) { ex = Math.random() * canvas.width; ey = canvas.height + 20; }
        else if (edge === 2) { ex = -20; ey = Math.random() * canvas.height; }
        else { ex = canvas.width + 20; ey = Math.random() * canvas.height; }

        enemies.push({ x: ex, y: ey, radius: 12, speed: 1.5, color: "#ff3333" });
    }, 1500);

    function update() {
        if (gameOver) return;

        // Gerak Player (WASD)
        if (keys['w'] && player.y > player.radius) player.y -= player.speed;
        if (keys['s'] && player.y < canvas.height - player.radius) player.y += player.speed;
        if (keys['a'] && player.x > player.radius) player.x -= player.speed;
        if (keys['d'] && player.x < canvas.width - player.radius) player.x += player.speed;

        // Update Peluru
        bullets.forEach((b, index) => {
            b.x += b.dx;
            b.y += b.dy;
            if (b.x < 0 || b.x > canvas.width || b.y < 0 || b.y > canvas.height) {
                bullets.splice(index, 1);
            }
        });

        // Update Musuh
        enemies.forEach((en, eIndex) => {
            let angle = Math.atan2(player.y - en.y, player.x - en.x);
            en.x += Math.cos(angle) * en.speed;
            en.y += Math.sin(angle) * en.speed;

            // Cek Tabrakan Musuh ke Player
            let distPlayer = Math.hypot(player.x - en.x, player.y - en.y);
            if (distPlayer < player.radius + en.radius) {
                player.health -= 1;
                if (player.health <= 0) gameOver = true;
            }

            // Cek Tabrakan Peluru ke Musuh
            bullets.forEach((b, bIndex) => {
                let distBullet = Math.hypot(b.x - en.x, b.y - en.y);
                if (distBullet < en.radius + b.radius) {
                    enemies.splice(eIndex, 1);
                    bullets.splice(bIndex, 1);
                    score += 10;
                }
            });
        });
    }

    function draw() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // Gambar Area Bermain (Gaya Map)
        ctx.fillStyle = "#1e5108";
        ctx.fillRect(50, 50, canvas.width - 100, canvas.height - 100);

        // Gambar Player
        ctx.beginPath();
        ctx.arc(player.x, player.y, player.radius, 0, Math.PI * 2);
        ctx.fillStyle = player.color;
        ctx.fill();
        ctx.closePath();

        // Gambar Peluru
        bullets.forEach(b => {
            ctx.beginPath();
            ctx.arc(b.x, b.y, b.radius, 0, Math.PI * 2);
            ctx.fillStyle = "#ffff00";
            ctx.fill();
            ctx.closePath();
        });

        // Gambar Musuh
        enemies.forEach(en => {
            ctx.beginPath();
            ctx.arc(en.x, en.y, en.radius, 0, Math.PI * 2);
            ctx.fillStyle = en.color;
            ctx.fill();
            ctx.closePath();
        });

        // Tampilkan Skor & Darah di Canvas
        ctx.fillStyle = "white";
        ctx.font = "16px Arial";
        ctx.fillText("Darah: " + player.health, 20, 30);
        ctx.fillText("Score: " + score, canvas.width - 100, 30);

        if (gameOver) {
            ctx.fillStyle = "rgba(0, 0, 0, 0.8)";
            ctx.fillRect(0, 0, canvas.width, canvas.height);
            ctx.fillStyle = "red";
            ctx.font = "40px Arial";
            ctx.textAlign = "center";
            ctx.fillText("GAME OVER", canvas.width / 2, canvas.height / 2 - 20);
            ctx.fillStyle = "white";
            ctx.font = "20px Arial";
            ctx.fillText("Refresh halaman untuk main lagi", canvas.width / 2, canvas.height / 2 + 20);
        }
    }

    function loop() {
        update();
        draw();
        requestAnimationFrame(loop);
    }

    loop();
</script>

</body>
</html>
