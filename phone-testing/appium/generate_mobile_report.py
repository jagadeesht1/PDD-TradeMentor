import os
import json
import sys
from datetime import datetime
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

def generate_report(results_json_path, report_xlsx_path):
    print(f"Generating styled Excel report from: {results_json_path}")
    
    if not os.path.exists(results_json_path):
        print(f"Error: Results file not found at {results_json_path}")
        return
        
    with open(results_json_path, 'r') as f:
        data = json.load(f)
        
    results = data.get('results', [])
    start_time_str = data.get('start_time', '')
    end_time_str = data.get('end_time', '')
    total_duration = data.get('total_duration_ms', 0)
    config_url = data.get('appium_url', '')
    platform = data.get('platform', 'Android')
    
    # Calculate stats
    total_steps = len(results)
    passed_steps = sum(1 for r in results if r['status'] == 'PASS')
    failed_steps = sum(1 for r in results if r['status'] == 'FAIL')
    pass_rate = (passed_steps / total_steps * 100) if total_steps > 0 else 0.0

    wb = openpyxl.Workbook()
    
    # Setup Summary Dashboard Sheet
    ws_dash = wb.active
    ws_dash.title = "Summary Dashboard"
    ws_dash.views.sheetView[0].showGridLines = True
    
    # Title Banner
    ws_dash.merge_cells('A1:B1')
    title_cell = ws_dash['A1']
    title_cell.value = "TradeMentor Mobile E2E Appium Report"
    title_cell.font = Font(name="Arial", size=15, bold=True, color="FFFFFF")
    title_cell.fill = PatternFill(start_color="0B121E", end_color="0B121E", fill_type="solid") # Dark Navy
    title_cell.alignment = Alignment(vertical="center", horizontal="center")
    ws_dash.row_dimensions[1].height = 40
    
    # Subheader
    ws_dash.row_dimensions[3].height = 25
    headers_dash = ['Execution Summary Metric', 'Details / Value']
    for col_idx, h in enumerate(headers_dash, 1):
        cell = ws_dash.cell(row=3, column=col_idx)
        cell.value = h
        cell.font = Font(name="Arial", size=11, bold=True, color="FFFFFF")
        cell.fill = PatternFill(start_color="141F32", end_color="141F32", fill_type="solid") # Slate
        cell.alignment = Alignment(vertical="center")

    thin_border = Border(
        left=Side(style='thin', color='DDDDDD'),
        right=Side(style='thin', color='DDDDDD'),
        top=Side(style='thin', color='DDDDDD'),
        bottom=Side(style='thin', color='DDDDDD')
    )

    metrics = [
        ('Run End Timestamp', datetime.now().strftime('%d-%b-%Y %I:%M:%S %p')),
        ('Appium Server URL', config_url),
        ('Mobile Platform OS', platform),
        ('Total Test Steps', total_steps),
        ('Passed Steps', passed_steps),
        ('Failed Steps', failed_steps),
        ('Pass Rate (%)', f"{pass_rate:.2f}%"),
        ('Total Suite Duration', f"{total_duration / 1000:.2f} seconds")
    ]

    for idx, (metric_name, val) in enumerate(metrics, 4):
        ws_dash.row_dimensions[idx].height = 20
        c1 = ws_dash.cell(row=idx, column=1, value=metric_name)
        c2 = ws_dash.cell(row=idx, column=2, value=val)
        c1.font = Font(name="Arial", size=10, bold=True)
        c2.font = Font(name="Arial", size=10)
        c1.border = thin_border
        c2.border = thin_border
        
        if metric_name == 'Pass Rate (%)':
            c2.font = Font(name="Arial", size=10, bold=True, color="00D09C" if pass_rate == 100 else "FF5353")

    ws_dash.column_dimensions['A'].width = 30
    ws_dash.column_dimensions['B'].width = 45

    # Setup Test Results Ledger Sheet
    ws_ledger = wb.create_sheet(title="Test Results Ledger")
    ws_ledger.views.sheetView[0].showGridLines = True
    
    headers_ledger = ['Test ID', 'Category', 'Test Step Description', 'Status', 'Duration (ms)', 'Details / Error message', 'Screenshot Reference']
    ws_ledger.row_dimensions[1].height = 25
    
    for col_idx, h in enumerate(headers_ledger, 1):
        cell = ws_ledger.cell(row=1, column=col_idx)
        cell.value = h
        cell.font = Font(name="Arial", size=11, bold=True, color="FFFFFF")
        cell.fill = PatternFill(start_color="141F32", end_color="141F32", fill_type="solid") # Slate
        cell.alignment = Alignment(vertical="center")

    for row_idx, r in enumerate(results, 2):
        ws_ledger.row_dimensions[row_idx].height = 22
        
        c_id = ws_ledger.cell(row=row_idx, column=1, value=r['id'])
        c_cat = ws_ledger.cell(row=row_idx, column=2, value=r['category'])
        c_desc = ws_ledger.cell(row=row_idx, column=3, value=r['description'])
        c_stat = ws_ledger.cell(row=row_idx, column=4, value=r['status'])
        c_dur = ws_ledger.cell(row=row_idx, column=5, value=r['duration_ms'])
        c_err = ws_ledger.cell(row=row_idx, column=6, value=r['error'] or 'N/A')
        
        c_id.font = Font(name="Arial", size=10)
        c_cat.font = Font(name="Arial", size=10)
        c_desc.font = Font(name="Arial", size=10)
        c_dur.font = Font(name="Arial", size=10)
        c_err.font = Font(name="Arial", size=10)
        
        # Borders
        for col in range(1, 8):
            ws_ledger.cell(row=row_idx, column=col).border = thin_border
            ws_ledger.cell(row=row_idx, column=col).alignment = Alignment(vertical="center")

        # Color-code Status
        if r['status'] == 'PASS':
            c_stat.font = Font(name="Arial", size=10, bold=True, color="00D09C")
        else:
            c_stat.font = Font(name="Arial", size=10, bold=True, color="FF5353")

        # Hyperlink to screenshot if failed
        c_scr = ws_ledger.cell(row=row_idx, column=7)
        if r.get('screenshot'):
            # Path to screenshot is relative to the reports folder
            rel_scr_path = os.path.join("..", "screenshots", r['screenshot'])
            c_scr.value = "View Screenshot"
            c_scr.hyperlink = rel_scr_path
            c_scr.font = Font(name="Arial", size=10, color="4285F4", underline="single")
        else:
            c_scr.value = "N/A"
            c_scr.font = Font(name="Arial", size=10)

    # Auto-adjust column widths
    for col in ws_ledger.columns:
        max_len = 0
        col_letter = get_column_letter(col[0].column)
        for cell in col:
            val_str = str(cell.value or '')
            if cell.hyperlink:
                val_str = "View Screenshot"
            if len(val_str) > max_len:
                max_len = len(val_str)
        ws_ledger.column_dimensions[col_letter].width = min(max(max_len + 4, 12), 65)

    wb.save(report_xlsx_path)
    print(f"Styled Excel report saved successfully to: {report_xlsx_path}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        # Default fallback
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        results_json = os.path.join(base_dir, "reports", "test_results.json")
        report_xlsx = os.path.join(base_dir, "reports", "appium_test_report.xlsx")
    else:
        results_json = sys.argv[1]
        report_xlsx = sys.argv[2]
        
    generate_report(results_json, report_xlsx)
