import pandas as pd
import glob
import sys
import os

def run_checks():
    # LA RUTA CORRECTA ADENTRO DEL CONTENEDOR
    BASE_DIR = "/app/datasets" 
    report = []
    
    print("🕵️‍♂️ Iniciando Inspección de Calidad de Materiales...")

    # Recorremos todas las subcarpetas usando os.walk en vez de glob
    for root, dirs, files in os.walk(BASE_DIR):
        for file in files:
            if file.endswith(".csv"):
                file_path = os.path.join(root, file)
                filename = os.path.basename(file)
                
                # Solo analizamos los bloques de consumo, ignoramos clima y feriados
                if "block" in filename:
                    df = pd.read_csv(file_path, nrows=100000) 
                    
                    # 1. VALIDACIÓN CRÍTICA
                    if 'LCLid' not in df.columns or df['LCLid'].isnull().any():
                        print(f"❌ ERROR CRÍTICO: {filename} tiene IDs faltantes o nulos.")
                        sys.exit(1) # Frena a Kestra
                        
                    # 2. VALIDACIÓN DE INCONGRUENCIAS
                    consumo_col = [col for col in df.columns if 'KWH/HH' in col.upper()]
                    
                    if consumo_col:
                        col_name = consumo_col[0]
                        df[col_name] = pd.to_numeric(df[col_name], errors='coerce')
                        
                        null_count = df[col_name].isnull().sum()
                        negative_values = (df[col_name] < 0).sum()
                        
                        report.append({
                            "archivo": filename,
                            "filas_muestreadas": len(df),
                            "nulos_consumo": int(null_count),
                            "valores_negativos": int(negative_values)
                        })
    
    # 3. GUARDAR EL REPORTE (AQUÍ ESTABA EL ERROR)
    report_path = os.path.join(BASE_DIR, "quality_report.csv")
    
    if report:
        pd.DataFrame(report).to_csv(report_path, index=False)
        print(f"✅ Inspección finalizada. Informe generado en {report_path}")
    else:
        print("⚠️ No se encontraron archivos de consumo para analizar.")

if __name__ == "__main__":
    run_checks()