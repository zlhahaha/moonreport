from pathlib import Path

from reportlab.lib.colors import HexColor, white
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output" / "pdf" / "MoonReport-OSC2026-project-proposal.pdf"
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

font_candidates = [
    Path(r"C:\Windows\Fonts\msyh.ttc"),
    Path(r"C:\Windows\Fonts\simhei.ttf"),
]
font_path = next((path for path in font_candidates if path.exists()), None)
if font_path is None:
    raise RuntimeError("No supported Chinese font found")
pdfmetrics.registerFont(TTFont("CN", str(font_path), subfontIndex=0))

navy = HexColor("#14213D")
blue = HexColor("#2563EB")
cyan = HexColor("#0EA5A8")
ink = HexColor("#172033")
muted = HexColor("#56647A")
pale = HexColor("#EEF5FF")
line = HexColor("#CFD9E8")

doc = SimpleDocTemplate(
    str(OUTPUT),
    pagesize=A4,
    leftMargin=17 * mm,
    rightMargin=17 * mm,
    topMargin=14 * mm,
    bottomMargin=13 * mm,
    title="MoonReport OSC 2026 项目申报书",
    author="MoonReport contributors",
)
title = ParagraphStyle(
    "title", fontName="CN", fontSize=22, leading=27, textColor=white
)
subtitle = ParagraphStyle(
    "subtitle", fontName="CN", fontSize=9.5, leading=14, textColor=white
)
section = ParagraphStyle(
    "section",
    fontName="CN",
    fontSize=11.5,
    leading=15,
    textColor=navy,
    spaceBefore=5,
    spaceAfter=3,
)
body = ParagraphStyle(
    "body", fontName="CN", fontSize=8.6, leading=12.4, textColor=ink
)
small = ParagraphStyle(
    "small", fontName="CN", fontSize=7.4, leading=10.5, textColor=muted
)
metric = ParagraphStyle(
    "metric", fontName="CN", fontSize=8.4, leading=11.5, textColor=navy
)


def p(text, style=body):
    return Paragraph(text, style)


story = []
header = Table(
    [[p("MoonReport", title), p("OSC 2026<br/>项目申报书", subtitle)]],
    colWidths=[125 * mm, 51 * mm],
)
header.setStyle(
    TableStyle(
        [
            ("BACKGROUND", (0, 0), (-1, -1), navy),
            ("BACKGROUND", (1, 0), (1, 0), blue),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ("LEFTPADDING", (0, 0), (-1, -1), 7 * mm),
            ("RIGHTPADDING", (0, 0), (-1, -1), 6 * mm),
            ("TOPPADDING", (0, 0), (-1, -1), 6 * mm),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 6 * mm),
        ]
    )
)
story.extend([header, Spacer(1, 5 * mm)])

metrics = Table(
    [[
        p("<b>项目方向</b><br/>MoonBit 开发工具基础库", metric),
        p("<b>当前状态</b><br/>4,113 行 / 84 项测试", metric),
        p("<b>目标规模</b><br/>4,000-10,000 行", metric),
        p("<b>开源协议</b><br/>Apache-2.0", metric),
    ]],
    colWidths=[44 * mm] * 4,
)
metrics.setStyle(
    TableStyle(
        [
            ("BACKGROUND", (0, 0), (-1, -1), pale),
            ("BOX", (0, 0), (-1, -1), 0.6, line),
            ("INNERGRID", (0, 0), (-1, -1), 0.4, line),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("LEFTPADDING", (0, 0), (-1, -1), 3 * mm),
            ("RIGHTPADDING", (0, 0), (-1, -1), 2 * mm),
            ("TOPPADDING", (0, 0), (-1, -1), 2.5 * mm),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 2.5 * mm),
        ]
    )
)
story.extend([metrics, Spacer(1, 3.5 * mm)])

story.extend(
    [
        p("项目简介与生态价值", section),
        p(
            "MoonReport 是一个纯 MoonBit 的源码感知诊断报告工具包，把字节偏移、"
            "校验失败和多处关联位置转换为清晰、稳定、可测试的人类可读报告与机器输出。"
            "它面向解析器、配置校验器、编译器、代码生成器、测试框架、linter 与 CLI，"
            "解决这些高频开发场景反复自建行列索引、代码片段、插入符、颜色和序列化的问题。"
        ),
        p("核心能力", section),
    ]
)
features = [
    ["01", "源码索引", "UTF-8 字节偏移、行列定位、CRLF、制表符与宽字符显示列。"],
    ["02", "诊断模型", "错误/警告/建议、代码、帮助、备注、多文件主次标签。"],
    ["03", "多种输出", "纯文本、ANSI、紧凑文本、JSON 与 JSON Lines。"],
    ["04", "稳定布局", "上下文窗口合并、远距折叠、多行标注和确定性快照。"],
    ["05", "安全修复", "结构化编辑、预览、冲突检测、JSON 和原子批量计划。"],
    ["06", "批量与移植", "统计、过滤、CI 阈值；核心适配 native、JS 与 Wasm。"],
]
feature_rows = [
    [p(f"<b>{number}</b>", metric), p(f"<b>{name}</b>"), p(description)]
    for number, name, description in features
]
feature_table = Table(feature_rows, colWidths=[11 * mm, 27 * mm, 138 * mm])
feature_table.setStyle(
    TableStyle(
        [
            ("TEXTCOLOR", (0, 0), (0, -1), cyan),
            ("LINEBELOW", (0, 0), (-1, -2), 0.35, line),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("LEFTPADDING", (0, 0), (-1, -1), 1.5 * mm),
            ("RIGHTPADDING", (0, 0), (-1, -1), 1.5 * mm),
            ("TOPPADDING", (0, 0), (-1, -1), 1.4 * mm),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 1.4 * mm),
        ]
    )
)
story.extend([feature_table, Spacer(1, 2 * mm)])

bottom = Table(
    [[
        [
            p("原创性与差异化", section),
            p(
                "截至 2026-07-28，对 mooncakes.io 与 GitHub 的 diagnostic、source span、"
                "error renderer 等组合检索未发现边界高度重合的可复用包。已排除已有 "
                "dotenv、diff、glob 与通用断言方向。实现为原创，不移植第三方上游代码；"
                "完整检索边界记录在仓库文档中。"
            ),
            p("验收与后续计划", section),
            p(
                "本地已通过 moon fmt --check、moon check --deny-warn、moon build、"
                "84 项测试、moon info 和可运行配置校验示例；CI 定义 Ubuntu/Windows "
                "双平台矩阵。当前 4,113 行 MoonBit 源码已达到赛题规模下限；后续可在"
                "保持稳定 API 的前提下扩展 SARIF 与编辑器协议适配。"
            ),
        ],
        [
            p("仓库与交付", section),
            p(
                "<b>拟公开地址</b><br/>github.com/zlhahaha/moonreport<br/><br/>"
                "<b>包名</b><br/>zlhahaha/moonreport<br/><br/>"
                "<b>可复现命令</b><br/>moon check --deny-warn<br/>"
                "moon build<br/>moon test<br/>moon run cmd/main",
                small,
            ),
            Spacer(1, 3 * mm),
            p(
                "备注：公开仓库、GitLink 镜像、线上 CI 与 mooncakes.io 发布需在外部"
                "账号操作后完成。申报前还需向组委会确认当前提交窗口。",
                small,
            ),
        ],
    ]],
    colWidths=[118 * mm, 58 * mm],
)
bottom.setStyle(
    TableStyle(
        [
            ("BACKGROUND", (1, 0), (1, 0), pale),
            ("BOX", (1, 0), (1, 0), 0.6, line),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("LEFTPADDING", (0, 0), (0, 0), 0),
            ("RIGHTPADDING", (0, 0), (0, 0), 5 * mm),
            ("LEFTPADDING", (1, 0), (1, 0), 4 * mm),
            ("RIGHTPADDING", (1, 0), (1, 0), 4 * mm),
            ("TOPPADDING", (0, 0), (-1, -1), 1 * mm),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 2 * mm),
        ]
    )
)
story.append(bottom)


def add_footer(canvas, _document):
    canvas.saveState()
    canvas.setStrokeColor(line)
    canvas.line(17 * mm, 10 * mm, 193 * mm, 10 * mm)
    canvas.setFont("CN", 7)
    canvas.setFillColor(muted)
    canvas.drawString(17 * mm, 6.5 * mm, "MoonReport - 让 MoonBit 开发工具的错误信息清晰、统一、可测试")
    canvas.drawRightString(193 * mm, 6.5 * mm, "2026-07-28 - 第 1 页")
    canvas.restoreState()


doc.build(story, onFirstPage=add_footer)
print(OUTPUT)
