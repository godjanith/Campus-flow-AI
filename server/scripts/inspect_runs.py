import pptx

prs = pptx.Presentation(r'C:\Users\janit\.gemini\antigravity\brain\bddab0db-1989-4323-b987-d683cb50a973\.user_uploaded\media_1795460091363.pptx')
slide = prs.slides[0]

for i, shape in enumerate(slide.shapes):
    if shape.has_text_frame:
        tf = shape.text_frame
        for p_idx, p in enumerate(tf.paragraphs):
            runs_info = []
            for r in p.runs:
                font_name = r.font.name
                font_size = r.font.size.pt if r.font.size else None
                bold = r.font.bold
                color = r.font.color.rgb if r.font.color and r.font.color.type == 1 else None
                runs_info.append(f"'{r.text}'(font={font_name}, sz={font_size}, b={bold}, c={color})")
            if runs_info:
                print(f"Shape {i:02d} [{shape.name}] P{p_idx}: {' '.join(runs_info)}")
