"""
Visualisasi Training History untuk Analisis Overfitting/Underfitting
=====================================================================
Membuat grafik terpisah untuk setiap eksperimen:
1. Hyperparameter (LR=1e-3)
2. Augmentation (All Combined)
3. Architecture (BiLSTM 2x256)
"""

import json
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

# Paths to training history files
EXPERIMENTS = [
    {
        "name": "Hyperparameter (LR=1e-3, Batch=32)",
        "short_name": "Hyperparameter",
        "path": Path(r"D:\Dokumen Kuliah\TA\Kode Kaggle\Experiment\2_19_2026_Eksperiment_LR_Batch\experiments\kaggleworkingexperimentsexp_hyperparams_20260219_082347\training_history.json"),
        "color": "#2E86AB",
        "filename": "loss_hyperparameter_lr1e3.png"
    },
    {
        "name": "Augmentation (All Combined)",
        "short_name": "Augmentation",
        "path": Path(r"D:\Dokumen Kuliah\TA\Kode Kaggle\Experiment\2_22_2026_Eksperiment_Augmentasi\experiments_all_only\exp_augmentation_20260223_010942\training_history.json"),
        "color": "#E94F37",
        "filename": "loss_augmentation_all_combined.png"
    },
    {
        "name": "Architecture (BiLSTM 2x256)",
        "short_name": "Architecture",
        "path": Path(r"D:\Dokumen Kuliah\TA\Kode Kaggle\Experiment\2_23_2026_Eksperiment_RNN\exp_architecture_rnn_20260223_042857\training_history.json"),
        "color": "#28A745",
        "filename": "loss_architecture_bilstm_2x256.png"
    },
]

def load_history(path):
    """Load training history from JSON file"""
    with open(path, 'r') as f:
        return json.load(f)

def plot_single_experiment(exp):
    """Create individual plot for one experiment"""
    
    history = load_history(exp['path'])
    
    train_loss = history['train_loss']
    val_loss = history['val_loss']
    epochs = range(1, len(train_loss) + 1)
    
    # Create figure
    fig, ax = plt.subplots(figsize=(10, 6))
    
    # Plot train and val loss
    ax.plot(epochs, train_loss, label='Train Loss', color=exp['color'], 
            linewidth=2.5, linestyle='-', marker='o', markevery=10, markersize=4)
    ax.plot(epochs, val_loss, label='Validation Loss', color=exp['color'], 
            linewidth=2.5, linestyle='--', alpha=0.8, marker='s', markevery=10, markersize=4)
    
    # Fill gap between train and val
    ax.fill_between(epochs, train_loss, val_loss, alpha=0.15, color=exp['color'])
    
    # Calculate metrics
    final_train = train_loss[-1]
    final_val = val_loss[-1]
    min_val = min(val_loss)
    min_val_epoch = val_loss.index(min_val) + 1
    gap = final_val - final_train
    
    # Mark best validation point
    ax.axvline(x=min_val_epoch, color='green', linestyle=':', linewidth=1.5, alpha=0.7)
    ax.scatter([min_val_epoch], [min_val], color='green', s=100, zorder=5, 
               marker='*', label=f'Best Val (Epoch {min_val_epoch})')
    
    # Labels and title
    ax.set_xlabel('Epoch', fontsize=12, fontweight='bold')
    ax.set_ylabel('Loss (CTC)', fontsize=12, fontweight='bold')
    ax.set_title(f'Training vs Validation Loss\n{exp["name"]}', 
                 fontsize=14, fontweight='bold')
    ax.legend(loc='upper right', fontsize=11, framealpha=0.9)
    ax.grid(True, alpha=0.3, linestyle='-')
    ax.set_xlim([1, len(train_loss)])
    ax.set_ylim([0, max(max(train_loss[:20]), max(val_loss[:20])) * 1.1])  # Focus on early epochs scale
    
    # Add annotation box with metrics
    textstr = '\n'.join([
        f'Final Train Loss: {final_train:.4f}',
        f'Final Val Loss: {final_val:.4f}',
        f'Gap (Val-Train): {gap:.4f}',
        f'Best Val Loss: {min_val:.4f}',
        f'Best Epoch: {min_val_epoch}',
        f'Total Epochs: {len(train_loss)}'
    ])
    props = dict(boxstyle='round,pad=0.5', facecolor='lightyellow', alpha=0.9, edgecolor='gray')
    ax.text(0.98, 0.65, textstr, transform=ax.transAxes, fontsize=10,
            verticalalignment='top', horizontalalignment='right', bbox=props)
    
    plt.tight_layout()
    plt.savefig(exp['filename'], dpi=150, bbox_inches='tight', facecolor='white')
    plt.show()
    
    print(f"[SAVED] {exp['filename']}")
    print(f"   Train Loss: {final_train:.4f} | Val Loss: {final_val:.4f} | Gap: {gap:.4f}")
    print(f"   Best Val: {min_val:.4f} at Epoch {min_val_epoch}")
    print()
    
    return {
        'name': exp['short_name'],
        'final_train': final_train,
        'final_val': final_val,
        'gap': gap,
        'min_val': min_val,
        'min_val_epoch': min_val_epoch,
        'total_epochs': len(train_loss)
    }

if __name__ == "__main__":
    # Set encoding for Windows console
    import sys
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    
    print("="*60)
    print("[INFO] Visualizing Training History - Individual Charts")
    print("="*60)
    print()
    
    results = []
    
    # Create individual plots for each experiment
    for exp in EXPERIMENTS:
        print(f"[PROCESSING] {exp['name']}")
        print("-"*50)
        result = plot_single_experiment(exp)
        results.append(result)
    
    # Summary table
    print("\n" + "="*70)
    print("[SUMMARY TABLE]")
    print("="*70)
    print(f"{'Experiment':<20} {'Train':<10} {'Val':<10} {'Gap':<10} {'Best Val':<10} {'Epoch':<8}")
    print("-"*70)
    for r in results:
        print(f"{r['name']:<20} {r['final_train']:<10.4f} {r['final_val']:<10.4f} {r['gap']:<10.4f} {r['min_val']:<10.4f} {r['min_val_epoch']:<8}")
    print("="*70)
