import pandas as pd
import glob
import sys
import os

def run_checks():
    files = glob.glob("/data/*.csv")
    report = []
    
    for f in files:
        # Leemos una muestra o el archivo completo según potencia del i7
        df = pd.read_csv(f, nrows=100000) 
        filename = os.path.basename(f)
        
        # 1. VALIDACIÓN CRÍTICA (Frenar si falla)
        if 'LCLid' not in df.columns or df['LCLid'].isnull().any():
            print(f"ERROR CRÍTICO: {filename} tiene IDs faltantes o nulos.")
            sys.exit(1) # Código de salida 1 frena a Kestra
            
        # 2. VALIDACIÓN DE INCONGRUENCIAS (Para informar a dbt)
        null_count = df['KWH/hh'].isnull().sum()
        negative_values = (df['KWH/hh'] < 0).sum()
        
        report.append({
            "archivo": filename,
            "filas_mureadas": len(df),
            "nulos_consumo": int(null_count),
            "valores_negativos": int(negative_values)
        })
    
    # Guardamos el informe de "anomalías" para la siguiente fase
    pd.DataFrame(report).to_csv("/data/quality_report.csv", index=False)
    print("Inspección finalizada. Informe de anomalías generado en /data/quality_report.csv")

if __name__ == "__main__":
    run_checks()