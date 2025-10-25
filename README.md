# Cache Controller - Verilog Implementation

A parameterized direct-mapped write-through cache controller implemented in Verilog for single-cycle processor integration.

## 🎯 Features

- **Direct-Mapped Cache**: 16KB cache with 1024 lines
- **Write-Through Policy**: All writes propagate to main memory
- **Configurable Parameters**: Cache size, block size, associativity
- **Cache Line Size**: 16 bytes (128 bits)
- **Processor Interface**: 32-bit data width
- **FSM-Based Control**: Clean state machine implementation
- **Memory Latency Handling**: Configurable n-cycle memory latency

## 📊 Architecture

### Specifications

<img width="428" height="394" alt="image" src="https://github.com/user-attachments/assets/f8d928b1-0c74-4df1-8a2e-7ddc78a56b83" />

### RTL View of the Entire System

<img width="747" height="673" alt="image" src="https://github.com/user-attachments/assets/6f8756c3-110e-4566-8207-b7829bdd2fdc" />


### Cache Organization
```
Address [31:0] Breakdown:
┌────────────────┬──────────────┬──────────────┐
│  Tag (18 bits) │ Index (10)   │ Offset (4)   │
│    [31:14]     │   [13:4]     │    [3:0]     │
└────────────────┴──────────────┴──────────────┘
```

- **Cache Size**: 16 KB
- **Number of Lines**: 1024
- **Block Size**: 16 bytes (4 words)
- **Associativity**: Direct-mapped

## 🗂️ Project Structure
```
cache-controller-verilog/
├── rtl/                          # RTL source files
│   ├── cache_controller.v        # Main cache controller with FSM
│   ├── data_array.v              # Cache data storage
│   ├── data_memory_subsystem.v   # Top-level integration
│   └── main_memory.v             # Main memory simulator
├── testbench/                    # Verification testbenches
├── docs/                         # Documentation and specs
│   └── CacheProject.pdf          # Original project specification
├── .gitignore                    # Git ignore patterns
└── README.md                     # This file
```

## 🔧 Module Descriptions

### 1. `cache_controller.v`
- **Purpose**: Control logic and FSM for cache operations
- **Features**:
  - Tag array (1024 x 18 bits)
  - Valid bit array (1024 bits)
  - 3-state FSM: IDLE, ALLOCATE, WRITE_MEMORY
  - Hit/miss detection
  - Flush operation support

### 2. `data_array.v`
- **Purpose**: Storage for cached data blocks
- **Features**:
  - 1024 cache lines × 128 bits each
  - Word-level access (32-bit)
  - Refill operation (load full cache line)
  - Update operation (modify single word)

### 3. `data_memory_subsystem.v`
- **Purpose**: Top-level integration module
- **Features**:
  - Address decoding (tag, index, offset extraction)
  - Module interconnections
  - Clean interface to processor

### 4. `main_memory.v`
- **Purpose**: Main memory simulation with configurable latency
- **Features**:
  - Parameterized memory size (default 256KB)
  - Configurable access latency (default 3 cycles)
  - Burst read (128-bit cache line)
  - Single-word write (32-bit)

## ⚙️ Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `CACHE_LINES` | 1024 | Number of cache lines |
| `TAG_WIDTH` | 18 | Tag field width |
| `INDEX_WIDTH` | 10 | Index field width |
| `OFFSET_WIDTH` | 4 | Block offset width |
| `DATA_WIDTH` | 32 | Processor data width |
| `BLOCK_WIDTH` | 128 | Cache line width |
| `MEM_SIZE` | 65536 | Memory size (words) |
| `LATENCY` | 3 | Memory access cycles |

## 🚀 How to Use

### Simulation

1. **Using ModelSim/QuestaSim:**
```bash
   # Compile all files
   vlog rtl/*.v testbench/tb_cache_controller.v
   
   # Run simulation
   vsim -c tb_cache_controller -do "run -all; quit"
```

2. **Using Icarus Verilog:**
```bash
   # Compile
   iverilog -o cache_sim rtl/*.v testbench/tb_cache_controller.v
   
   # Run
   vvp cache_sim
   
   # View waveform
   gtkwave dump.vcd
```

### Integration
```verilog
data_memory_subsystem #(
    .CACHE_LINES(1024),
    .LATENCY(3)
) cache_system (
    .clk(clk),
    .rst(rst),
    .addr(cpu_addr),
    .read(cpu_read),
    .write(cpu_write),
    .wdata(cpu_wdata),
    .rdata(cpu_rdata),
    .stall(cpu_stall),
    .flush(cpu_flush)
);
```

## 📈 Performance Characteristics

| Operation | Hit Latency | Miss Latency | Notes |
|-----------|-------------|--------------|-------|
| **Read Hit** | 1 cycle | - | Data returned immediately |
| **Read Miss** | - | 4 cycles | 1 (detection) + 3 (memory) |
| **Write Hit** | 4 cycles | - | Cache + memory (write-through) |
| **Write Miss** | 4 cycles | - | Memory only (no-write-allocate) |
| **Flush** | 1 cycle | - | Clear all valid bits |

## 🎓 Key Design Decisions

1. **Write-Through Policy**
   - Simplifies design (no dirty bits needed)
   - Ensures memory consistency
   - Trade-off: Higher write latency

2. **Direct-Mapped**
   - Simple hit detection (single comparison)
   - Potential for conflict misses
   - Good for learning fundamentals

3. **No-Write-Allocate**
   - Write misses go directly to memory
   - Doesn't allocate cache line on write miss
   - Common pairing with write-through

## 🔄 FSM State Transitions
```
     IDLE
      │
      ├─► Read Hit ──────────► IDLE
      │
      ├─► Read Miss ─────────► ALLOCATE ──► IDLE
      │                         (wait mem)
      │
      └─► Write (any) ───────► WRITE_MEMORY ──► IDLE
                                (wait mem)
```

## 🐛 Known Limitations

- Direct-mapped: Potential conflict misses
- Write-through: High write bandwidth to memory
- No support for outstanding misses
- Single-cycle tag/data access (may not meet timing in high-freq designs)

## 🔮 Future Enhancements

- [ ] Set-associative (2-way, 4-way)
- [ ] LRU replacement policy
- [ ] Write-back policy with dirty bits
- [ ] Non-blocking cache
- [ ] Performance counters (hit rate, miss rate)
- [ ] Burst write support

## 📚 References

- Computer Architecture: A Quantitative Approach (Hennessy & Patterson)
- Cache design principles and trade-offs
- Verilog HDL synthesis and coding standards

## 👤 Author

**Your Name**
- GitHub: [@farrukhzaf](https://github.com/farrukhzaf)
- LinkedIn: [Mohammad Farukh Zafar](https://linkedin.com/in/farukhzafar)
- Email: farukhzafar@iisc.ac.in

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

⭐ **If you found this helpful, please star this repository!**
