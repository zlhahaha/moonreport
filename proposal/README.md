# Proposal generation

The checked-in PDF is generated from `generate_proposal.py` so that its
contents remain reviewable and reproducible.

Requirements:

- Python 3.11 or newer
- ReportLab
- A Chinese font available on the host (the script checks common Windows
  and Linux font locations)

From the repository root:

```sh
python proposal/generate_proposal.py
```

The output is written to:

```text
output/pdf/MoonReport-OSC2026-project-proposal.pdf
```

For visual review, render the PDF with Poppler and inspect the resulting
page image:

```sh
pdftoppm -png -r 150 output/pdf/MoonReport-OSC2026-project-proposal.pdf proposal/rendered/proposal
```

The `proposal/rendered/` directory is intentionally ignored because it
only contains local review artifacts.
