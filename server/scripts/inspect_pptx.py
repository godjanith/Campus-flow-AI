import pptx

prs = pptx.Presentation(r'C:\Users\janit\.gemini\antigravity\brain\bddab0db-1989-4323-b987-d683cb50a973\.user_uploaded\media_1795460091363.pptx')
print(f'Slide dimensions: {prs.slide_width.inches:.2f} x {prs.slide_height.inches:.2f} inches ({prs.slide_width.pt:.1f} x {prs.slide_height.pt:.1f} pt)')
for s_idx, slide in enumerate(prs.slides):
    print(f'Slide {s_idx}: {len(slide.shapes)} shapes')
    for sh_idx, shape in enumerate(slide.shapes):
        txt = shape.text_frame.text[:60].replace('\n', ' ') if shape.has_text_frame else ''
        print(f'  Shape {sh_idx:02d}: name="{shape.name}" | type={shape.shape_type} | pos=({shape.left.inches:.2f}, {shape.top.inches:.2f}, {shape.width.inches:.2f}, {shape.height.inches:.2f}) | text="{txt}"')
