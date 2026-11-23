import qrcode
from PIL import Image, ImageDraw, ImageFont
import os

scratch_dir = r'C:\Users\janit\.gemini\antigravity\brain\bddab0db-1989-4323-b987-d683cb50a973\scratch'

# 1. Generate QR Code
qr = qrcode.QRCode(
    version=1,
    error_correction=qrcode.constants.ERROR_CORRECT_H,
    box_size=10,
    border=2,
)
qr.add_data('https://github.com/godjanith/Campus-flow-AI')
qr.make(fit=True)
qr_img = qr.make_image(fill_color='#0F294A', back_color='white').convert('RGB')
qr_path = os.path.join(scratch_dir, 'campusflow_qr.png')
qr_img.save(qr_path)
print(f'QR Code saved to {qr_path}')

# 2. Generate Sleek Architecture Diagram for the Poster
# Width: ~1200px, Height: ~400px (3:1 ratio matching ~3.81 x 1.28 in)
w, h = 1200, 390
diag = Image.new('RGB', (w, h), color='#FFFFFF')
draw = ImageDraw.Draw(diag)

# Colors
navy = (15, 41, 74)
gold = (197, 155, 39)
card_bg = (248, 250, 252)
border_c = (226, 232, 240)
text_c = (30, 41, 59)
accent_blue = (30, 64, 175)
accent_green = (5, 150, 105)

# Background border
draw.rounded_rectangle([2, 2, w-3, h-3], radius=12, fill='#F8FAFC', outline=border_c, width=2)

# Nodes: 4 workflow boxes
boxes = [
    {
        'title': '1. FLUTTER MOBILE',
        'sub': '• Student Geotag (GPS)\n• Photo Evidence\n• Offline SQLite Queue',
        'badge': 'EDGE CLIENT',
        'bcolor': accent_blue,
        'rect': [30, 30, 280, 360]
    },
    {
        'title': '2. GATEWAY & BUS',
        'sub': '• Node.js + Express 4\n• Central JWT Auth\n• Socket.io Event Bus',
        'badge': 'REST / SOCKET',
        'bcolor': navy,
        'rect': [325, 30, 575, 360]
    },
    {
        'title': '3. GEMINI 1.5 PRO',
        'sub': '• Multimodal Vision AI\n• Severity Triage (<4s)\n• Automated Safety SOP',
        'badge': 'AI REASONING',
        'bcolor': gold,
        'rect': [620, 30, 870, 360]
    },
    {
        'title': '4. COMMAND TWIN',
        'sub': '• Leaflet Satellite Twin\n• MongoDB Persistence\n• Instant Crew Dispatch',
        'badge': 'OPERATIONS',
        'bcolor': accent_green,
        'rect': [915, 30, 1165, 360]
    }
]

# Try to load a nice font, fallback to default
try:
    font_title = ImageFont.truetype('arialbd.ttf', 20)
    font_badge = ImageFont.truetype('arialbd.ttf', 13)
    font_body = ImageFont.truetype('arial.ttf', 16)
    font_arrow = ImageFont.truetype('arialbd.ttf', 32)
except Exception:
    font_title = ImageFont.load_default()
    font_badge = ImageFont.load_default()
    font_body = ImageFont.load_default()
    font_arrow = ImageFont.load_default()

for b in boxes:
    r = b['rect']
    # White card with shadow-like border
    draw.rounded_rectangle(r, radius=10, fill='#FFFFFF', outline=border_c, width=2)
    # Header strip
    draw.rounded_rectangle([r[0], r[1], r[2], r[1]+48], radius=8, fill=navy)
    draw.rectangle([r[0], r[1]+36, r[2], r[1]+48], fill=navy) # fill bottom corners
    
    # Title
    draw.text((r[0]+14, r[1]+14), b['title'], fill='#FFFFFF', font=font_title)
    
    # Badge
    draw.rounded_rectangle([r[0]+14, r[1]+60, r[0]+140, r[1]+84], radius=6, fill=card_bg, outline=b['bcolor'], width=1)
    draw.text((r[0]+22, r[1]+65), b['badge'], fill=b['bcolor'], font=font_badge)
    
    # Body lines
    lines = b['sub'].split('\n')
    y_pos = r[1] + 102
    for line in lines:
        draw.text((r[0]+16, y_pos), line, fill=text_c, font=font_body)
        y_pos += 32

# Connecting Arrows
arrows = [
    ((285, 185), (320, 185)),
    ((580, 185), (615, 185)),
    ((875, 185), (910, 185)),
]

for start, end in arrows:
    draw.text((start[0]+6, start[1]-20), '➜', fill=gold, font=font_arrow)

diag_path = os.path.join(scratch_dir, 'campusflow_architecture.png')
diag.save(diag_path)
print(f'Architecture diagram saved to {diag_path}')
