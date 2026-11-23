from PIL import Image, ImageDraw, ImageFont
import os

scratch_dir = r'C:\Users\janit\.gemini\antigravity\brain\bddab0db-1989-4323-b987-d683cb50a973\scratch'
assets_dir = r'C:\Users\janit\Desktop\campusflow-ai\docs\poster_assets'
output_png = r'C:\Users\janit\Desktop\campusflow-ai\docs\ZENITH_LABS_CampusFlow_AI_Poster.png'
output_root_png = r'C:\Users\janit\Desktop\campusflow-ai\ZENITH_LABS_CampusFlow_AI_Poster.png'

# Standard A3 Landscape @ 200 DPI = 3307 x 2339 pixels
W, H = 3307, 2339
img = Image.new('RGB', (W, H), color='#F8FAFC')
draw = ImageDraw.Draw(img)

# Color Palette
NAVY = (15, 41, 74)
GOLD = (197, 155, 39)
CARD_BG = (255, 255, 255)
BORDER = (226, 232, 240)
TEXT_DARK = (30, 41, 59)
TEXT_MUTED = (100, 116, 139)
LIGHT_BG = (248, 250, 252)

# Load System Fonts
try:
    font_title = ImageFont.truetype('georgiab.ttf', 58)
    font_sub = ImageFont.truetype('arialbd.ttf', 24)
    font_team_name = ImageFont.truetype('arialbd.ttf', 23)
    font_team_members = ImageFont.truetype('arialbd.ttf', 21)
    font_card_num = ImageFont.truetype('arialbd.ttf', 20)
    font_card_title = ImageFont.truetype('arialbd.ttf', 23)
    font_body = ImageFont.truetype('arial.ttf', 19)
    font_body_bold = ImageFont.truetype('arialbd.ttf', 19)
    font_small = ImageFont.truetype('arial.ttf', 16)
    font_footer = ImageFont.truetype('arialbd.ttf', 19)
    font_footer_ref = ImageFont.truetype('arial.ttf', 16)
except Exception:
    font_title = font_sub = font_team_name = font_team_members = font_card_num = font_card_title = font_body = font_body_bold = font_small = font_footer = font_footer_ref = ImageFont.load_default()

# ── 1. HEADER LOGOS ROW ──
header_box = [60, 40, W - 60, 180]
draw.rounded_rectangle(header_box, radius=12, fill='#FFFFFF', outline=BORDER, width=2)

# Load and paste logos
logos = ['image1.png', 'image2.png', 'image3.png', 'image4.png', 'image5.png', 'image6.png', 'image7.png']
logo_imgs = []
for l_name in logos:
    p = os.path.join(assets_dir, l_name)
    if os.path.exists(p):
        logo_imgs.append(Image.open(p).convert('RGBA'))

# Available width inside header: ~3187px, height: 140px
max_logo_h = 110
num_logos = len(logo_imgs)
spacing = (W - 120) / num_logos

for idx, limg in enumerate(logo_imgs):
    # Scale while maintaining aspect ratio
    aspect = limg.width / limg.height
    new_h = min(max_logo_h, int(limg.height * 0.9))
    new_w = int(new_h * aspect)
    # Clamp width if too wide
    max_w = int(spacing - 40)
    if new_w > max_w:
        new_w = max_w
        new_h = int(new_w / aspect)
    
    resized = limg.resize((new_w, new_h), Image.Resampling.LANCZOS)
    cx = int(60 + (idx + 0.5) * spacing)
    cy = int(40 + 70)
    px = cx - new_w // 2
    py = cy - new_h // 2
    
    img.paste(resized, (px, py), resized)
    
    # Divider between logos
    if idx < num_logos - 1:
        div_x = int(60 + (idx + 1) * spacing)
        draw.line([(div_x, 60), (div_x, 160)], fill=BORDER, width=2)

# Gold separator bar below logos
draw.line([(60, 196), (W - 60, 196)], fill=GOLD, width=4)

# ── 2. TITLE & TAGLINE ──
title_text = "CAMPUSFLOW AI"
sub_text = "AUTONOMOUS SPATIAL INFRASTRUCTURE INTELLIGENCE & MULTIMODAL INCIDENT TRIAGE ECOSYSTEM"

title_bbox = draw.textbbox((0, 0), title_text, font=font_title)
title_w = title_bbox[2] - title_bbox[0]
draw.text(((W - title_w) // 2, 212), title_text, fill=NAVY, font=font_title)

sub_bbox = draw.textbbox((0, 0), sub_text, font=font_sub)
sub_w = sub_bbox[2] - sub_bbox[0]
draw.text(((W - sub_w) // 2, 285), sub_text, fill=GOLD, font=font_sub)

# ── 3. TEAM BAR ──
team_box = [60, 335, W - 60, 395]
draw.rounded_rectangle(team_box, radius=8, fill=NAVY)
draw.rounded_rectangle([60, 335, 75, 395], radius=6, fill=GOLD) # Gold accent strip on left

draw.text((95, 350), "TEAM NAME: ZENITH LABS", fill=GOLD, font=font_team_name)
members_text = "MEMBERS: Janith V C (Lead) – 20252MCA0318   |   Aishwarya M – 20252MCA0101   |   Rahul R – 20252MCA0301"
draw.text((620, 352), members_text, fill='#FFFFFF', font=font_team_members)

# ── 4. 3-COLUMN LAYOUT ──
col_gap = 35
col_w = (W - 120 - 2 * col_gap) // 3 # approx 1030 px each
col1_x = 60
col2_x = col1_x + col_w + col_gap
col3_x = col2_x + col_w + col_gap

top_y = 425
footer_h = 75
bottom_y = H - 55 - footer_h # approx 2209

# Helper to draw a modern Card
def draw_card(x, y, w, h, num_str, title_str):
    draw.rounded_rectangle([x, y, x + w, y + h], radius=10, fill=CARD_BG, outline=BORDER, width=2)
    # Header strip
    draw.rounded_rectangle([x + 16, y + 14, x + 56, y + 46], radius=6, fill=NAVY)
    num_bb = draw.textbbox((0, 0), num_str, font=font_card_num)
    nw = num_bb[2] - num_bb[0]
    draw.text((x + 36 - nw//2, y + 19), num_str, fill=GOLD, font=font_card_num)
    draw.text((x + 72, y + 18), title_str, fill=NAVY, font=font_card_title)
    draw.line([(x + 16, y + 54), (x + w - 16, y + 54)], fill=BORDER, width=1)

# Helper to wrap text
def draw_wrapped_text(x, y, max_w, text, font, fill_color, line_spacing=28):
    words = text.split(' ')
    lines = []
    curr = []
    for w in words:
        test_line = ' '.join(curr + [w])
        bb = draw.textbbox((0, 0), test_line, font=font)
        if bb[2] - bb[0] <= max_w:
            curr.append(w)
        else:
            lines.append(' '.join(curr))
            curr = [w]
    if curr:
        lines.append(' '.join(curr))
    
    cur_y = y
    for line in lines:
        draw.text((x, cur_y), line, fill=fill_color, font=font)
        cur_y += line_spacing
    return cur_y

# Helper to draw bullet list
def draw_bullets(x, y, max_w, items, font_b, font_r, fill_color, line_spacing=27, item_gap=10):
    cur_y = y
    for bold_prefix, rest in items:
        # bullet symbol
        draw.text((x, cur_y - 2), "▪", fill=GOLD, font=font_b)
        text_full = f"{bold_prefix} {rest}"
        # Measure bold prefix
        b_bb = draw.textbbox((0, 0), bold_prefix, font=font_b)
        prefix_w = b_bb[2] - b_bb[0]
        
        # Word wrap with indentation
        words = rest.split(' ')
        lines = []
        curr = []
        # First line includes bold prefix
        for w in words:
            test_line = ' '.join(curr + [w])
            bb = draw.textbbox((0, 0), test_line, font=font_r)
            if prefix_w + 10 + (bb[2] - bb[0]) <= max_w - 25:
                curr.append(w)
            else:
                lines.append(' '.join(curr))
                curr = [w]
                break
        
        # Subsequent lines
        remaining_words = words[len(curr):]
        sub_curr = []
        for w in remaining_words:
            test_line = ' '.join(sub_curr + [w])
            bb = draw.textbbox((0, 0), test_line, font=font_r)
            if (bb[2] - bb[0]) <= max_w - 25:
                sub_curr.append(w)
            else:
                lines.append(' '.join(sub_curr))
                sub_curr = [w]
        if sub_curr:
            lines.append(' '.join(sub_curr))
            
        # Draw first line
        draw.text((x + 22, cur_y), bold_prefix, fill=NAVY, font=font_b)
        if curr:
            draw.text((x + 22 + prefix_w + 8, cur_y), ' '.join(curr), fill=fill_color, font=font_r)
        cur_y += line_spacing
        
        # Draw subsequent lines
        for l in lines:
            draw.text((x + 22, cur_y), l, fill=fill_color, font=font_r)
            cur_y += line_spacing
            
        cur_y += item_gap
    return cur_y

# ── COLUMN 1 CARDS ──
# 01 Abstract
c1_h1 = 360
draw_card(col1_x, top_y, col_w, c1_h1, "01", "ABSTRACT")
draw_wrapped_text(
    col1_x + 20, top_y + 70, col_w - 40,
    "CampusFlow AI bridges the critical divide between university hazard reporting and immediate facility response. Combining a Royal-Light Flutter mobile client, Leaflet spatial digital twin, Google Gemini 1.5 Pro Multimodal Vision AI, and a real-time Socket.io bus, it autonomously geotags, prioritizes, and coordinates campus safety operations in under 4 seconds with offline fault tolerance.",
    font_body, TEXT_DARK, line_spacing=30
)

# 02 Problem Statement
c1_y2 = top_y + c1_h1 + 25
c1_h2 = 360
draw_card(col1_x, c1_y2, col_w, c1_h2, "02", "PROBLEM STATEMENT")
draw_wrapped_text(
    col1_x + 20, c1_y2 + 70, col_w - 40,
    "Modern university campuses lack centralized, real-time spatial intelligence for structural hazards, electrical sparks, and plumbing leaks. Traditional facility ticketing is slow, text-only, and lacks automated severity triage or exact geolocation, leading to delayed repairs, student safety risks, and operational downtime across academic blocks.",
    font_body, TEXT_DARK, line_spacing=30
)

# 03 Objectives
c1_y3 = c1_y2 + c1_h2 + 25
c1_h3 = 450
draw_card(col1_x, c1_y3, col_w, c1_h3, "03", "OBJECTIVES")
draw_bullets(
    col1_x + 20, c1_y3 + 70, col_w - 40,
    [
        ("1-Tap Geotagged Reporting:", "Instant photo capture with automated campus geofencing."),
        ("Multimodal AI Triage:", "Autonomous classification of category, severity & ETA via Gemini in <4s."),
        ("Live 3D Spatial Twin:", "Real-time incident beacons & status synchronization over WebSockets."),
        ("Offline Zero-Loss Resilience:", "Bidirectional SQLite queue synchronizing automatically when online."),
    ],
    font_body_bold, font_body, TEXT_DARK, line_spacing=26, item_gap=12
)

# 06 Technologies Used
c1_y4 = c1_y3 + c1_h3 + 25
c1_h4 = bottom_y - c1_y4
draw_card(col1_x, c1_y4, col_w, c1_h4, "06", "TECHNOLOGIES USED")
draw_bullets(
    col1_x + 20, c1_y4 + 70, col_w - 40,
    [
        ("Mobile Client:", "Flutter 3.x (Material 3 Dark/Royal-Light), Provider, Google Maps / Leaflet."),
        ("Backend & Bus:", "Node.js, Express 4, Socket.io Bus, Multer, Helmet, Compression, JWT CAS."),
        ("Multimodal AI:", "Google Gemini 1.5 Pro API (Vision Triage + Autonomous Safety Copilot)."),
        ("Database & GIS:", "MongoDB Compass / Mongoose, Esri High-Resolution Satellite Map Tile Server."),
    ],
    font_body_bold, font_body, TEXT_DARK, line_spacing=26, item_gap=12
)

# ── COLUMN 2 CARDS ──
# 04 Proposed Solution
c2_h1 = 360
draw_card(col2_x, top_y, col_w, c2_h1, "04", "PROPOSED SOLUTION")
draw_wrapped_text(
    col2_x + 20, top_y + 70, col_w - 40,
    "An autonomous spatial dispatch ecosystem: Students capture hazard photos on Flutter mobile with precision GPS. The Node.js gateway streams the image to Google Gemini 1.5 Pro for zero-latency severity triage, safety advisories, and estimated resolution time. Verified incidents instantly populate the 3D satellite twin for swift facility crew dispatch and automated resolution tracking.",
    font_body, TEXT_DARK, line_spacing=30
)

# 05 Architecture & Workflow
c2_y2 = top_y + c2_h1 + 25
c2_h2 = bottom_y - c2_y2
draw_card(col2_x, c2_y2, col_w, c2_h2, "05", "SYSTEM ARCHITECTURE / WORKFLOW")

# 4 workflow step pills
step_w = (col_w - 60) // 4
steps_data = [
    ("1. INPUT", "Geotag + Photo"),
    ("2. PROCESS", "Node.js + Bus"),
    ("3. MODEL/DB", "Gemini + Mongo"),
    ("4. OUTPUT", "Twin + Dispatch")
]
for s_idx, (stitle, ssub) in enumerate(steps_data):
    sx = col2_x + 20 + s_idx * (step_w + 7)
    sy = c2_y2 + 70
    draw.rounded_rectangle([sx, sy, sx + step_w, sy + 65], radius=6, fill=LIGHT_BG, outline=BORDER, width=1)
    draw.text((sx + 10, sy + 10), stitle, fill=NAVY, font=font_body_bold)
    draw.text((sx + 10, sy + 36), ssub, fill=TEXT_MUTED, font=font_small)

# Paste Architecture Diagram Graphic
diag_p = os.path.join(scratch_dir, 'campusflow_architecture.png')
if os.path.exists(diag_p):
    diag_img = Image.open(diag_p).convert('RGB')
    target_dw = col_w - 40
    target_dh = int(c2_h2 - 180)
    resized_diag = diag_img.resize((target_dw, target_dh), Image.Resampling.LANCZOS)
    img.paste(resized_diag, (col2_x + 20, c2_y2 + 155))

# ── COLUMN 3 CARDS ──
# 07 QR Code / Demo Link
c3_h1 = 360
draw_card(col3_x, top_y, col_w, c3_h1, "07", "QR CODE / DEMO LINK")

qr_p = os.path.join(scratch_dir, 'campusflow_qr.png')
if os.path.exists(qr_p):
    qr_im = Image.open(qr_p).convert('RGB')
    qr_size = 230
    resized_qr = qr_im.resize((qr_size, qr_size), Image.Resampling.LANCZOS)
    draw.rounded_rectangle([col3_x + 20, top_y + 80, col3_x + 20 + qr_size + 8, top_y + 80 + qr_size + 8], radius=8, outline=NAVY, width=2)
    img.paste(resized_qr, (col3_x + 24, top_y + 84))

draw.rounded_rectangle([col3_x + 280, top_y + 80, col3_x + 580, top_y + 115], radius=6, fill='#EFF6FF', outline='#BFDBFE', width=1)
draw.text((col3_x + 295, top_y + 88), "LIVE GITHUB REPOSITORY", fill='#1E40AF', font=font_body_bold)

draw_wrapped_text(
    col3_x + 280, top_y + 130, col_w - 300,
    "Scan with your mobile camera to inspect full source code, architecture specifications, API documentation & live APK releases.",
    font_body, TEXT_DARK, line_spacing=26
)
draw.text((col3_x + 280, top_y + 250), "URL: github.com/godjanith/Campus-flow-AI", fill=NAVY, font=font_body_bold)

# 08 Results & Outcomes
c3_y2 = top_y + c3_h1 + 25
c3_h2 = 450
draw_card(col3_x, c3_y2, col_w, c3_h2, "08", "RESULTS & OUTCOMES")
draw_bullets(
    col3_x + 20, c3_y2 + 70, col_w - 40,
    [
        ("Triage Latency:", "Sub-4s multimodal hazard classification (vs 2-4 hours manual ticket dispatch)."),
        ("Geolocation Precision:", "Accurate to within 5m across 7 Presidency academic blocks."),
        ("Offline Reliability:", "100% incident delivery retention via SQLite/SharedPreferences cache."),
        ("Production Benchmark:", "0 analyzer warnings across Flutter & 100% clean production build."),
    ],
    font_body_bold, font_body, TEXT_DARK, line_spacing=26, item_gap=12
)

# 09 Future Scope & Conclusion
c3_y3 = c3_y2 + c3_h2 + 25
c3_h3 = bottom_y - c3_y3
draw_card(col3_x, c3_y3, col_w, c3_h3, "09", "FUTURE SCOPE & CONCLUSION")
draw_bullets(
    col3_x + 20, c3_y3 + 70, col_w - 40,
    [
        ("IoT Sensor Mesh:", "Acoustic vibration sensors for underground water & gas pipe leak detection."),
        ("Autonomous Drones:", "High-voltage exterior structural inspections & aerial thermal mapping."),
        ("BMS Integration:", "Direct handshake with university HVAC, power blades, and smart ID cards."),
        ("Conclusion:", "Proactive, autonomous safety intelligence maximizing campus reliability."),
    ],
    font_body_bold, font_body, TEXT_DARK, line_spacing=26, item_gap=12
)

# ── 5. FOOTER ──
footer_box = [60, bottom_y + 15, W - 60, bottom_y + 15 + footer_h]
draw.rounded_rectangle(footer_box, radius=8, fill=NAVY)
draw.line([(60, bottom_y + 15), (W - 60, bottom_y + 15)], fill=GOLD, width=3)

draw.text((90, bottom_y + 38), "CAMPUSFLOW AI", fill=GOLD, font=font_footer)
draw.text((290, bottom_y + 38), "• OFFICIAL OPERATIONS PORTAL • MERNOVA X PROJECT EXPO 2026", fill='#FFFFFF', font=font_footer)

ref_str = "REFERENCES: Google Gemini 1.5 Pro Multimodal Vision API, Flutter 3 SDK, React 18, Leaflet Spatial GIS, Presidency University GIS Map Coordinates."
draw.text((W - 1380, bottom_y + 40), ref_str, fill='#94A3B8', font=font_footer_ref)

# Save images
img.save(output_png, quality=95)
img.save(output_root_png, quality=95)
print(f"High-resolution A3 Poster image generated successfully at {output_png} and {output_root_png}")
