import pandas as pd
import glob
import sys
import os

def run_checks():
    # THE CORRECT PATH INSIDE THE CONTAINER
    BASE_DIR = "/app/datasets" 
    report = []
    
    print("🕵️‍♂️ Starting Material Quality Inspection...")

    # Iterate through all subfolders using os.walk instead of glob
    for root, dirs, files in os.walk(BASE_DIR):
        for file in files:
            if file.endswith(".csv"):
                file_path = os.path.join(root, file)
                filename = os.path.basename(file)
                
                # Only analyze consumption blocks, ignore weather and holidays
                if "block" in filename:
                    df = pd.read_csv(file_path, nrows=100000) 
                    
                    # 1. CRITICAL VALIDATION
                    if 'LCLid' not in df.columns or df['LCLid'].isnull().any():
                        print(f"❌ CRITICAL ERROR: {filename} has missing or null IDs.")
                        sys.exit(1) # Stops Kestra
                        
                    # 2. INCONSISTENCY VALIDATION
                    consumo_col = [col for col in df.columns if 'KWH/HH' in col.upper()]
                    
                    if consumo_col:
                        col_name = consumo_col[0]
                        df[col_name] = pd.to_numeric(df[col_name], errors='coerce')
                        
                        null_count = df[col_name].isnull().sum()
                        negative_values = (df[col_name] < 0).sum()
                        
                        report.append({
                            "file": filename,
                            "sampled_rows": len(df),
                            "null_consumption": int(null_count),
                            "negative_values": int(negative_values)
                        })
    
    # 3. SAVE THE REPORT (THE ERROR WAS HERE)
    report_path = os.path.join(BASE_DIR, "quality_report.csv")
    
    if report:
        pd.DataFrame(report).to_csv(report_path, index=False)
        print(f"✅ Inspection completed. Report generated at {report_path}")
    else:
        print("⚠️ No consumption files found to analyze.")

if __name__ == "__main__":
    run_checks()