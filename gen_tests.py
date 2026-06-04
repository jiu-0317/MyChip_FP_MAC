import subprocess, os, re, sys

DESIGN_FILES = "TOP.v FPU.v ACC.v ACC_adder.v ACC_R.v IR.v W_I_RF.v CONTROL.v SPI_slave.v mant_mult_lut.v"

with open("tb_TOP.v", "r", encoding="utf-8") as f:
    tb_original = f.read()

# tb_TOP.v의 첫 번째 initial block (USER CONFIG 영역)을 찾아 치환하는 패턴
pattern = re.compile(
    r"(initial begin\s*\n\s*// --- READ mode.*?^end)",
    re.DOTALL | re.MULTILINE
)

# =====================================================================
#  테스트 케이스 정의
#
#  각 테스트는 dict로 정의:
#    name      : 테스트 이름 (출력에 표시)
#    read_mode : "0" = E4M3, "1" = E5M2
#    wm        : Weight mode 리스트 (9개, 0=E4M3, 1=E5M2)
#    w         : Weight 값 리스트 (9개, hex string)
#    wc        : Weight 코멘트 (9개)
#    im        : Input mode 리스트 (9개)
#    i         : Input 값 리스트 (9개, hex string)
#    ic        : Input 코멘트 (9개)
#
#  E4M3 값 참고 (mode=0):
#    0.5  = 30   1.0  = 38   1.5  = 3C   2.0  = 40
#    3.0  = 44   4.0  = 48  -1.0  = B8  -2.0  = C0
#    zero = 00
#
#  E5M2 값 참고 (mode=1):
#    0.5  = 38   1.0  = 3C   1.5  = 3E   2.0  = 40
#    3.0  = 42   4.0  = 44  -1.0  = BC  -2.0  = C0
#    zero = 00
# =====================================================================

tests = [
    # --- 기본 동작 검증 ---
    {
        "name": "Test01: All 1.0 x 1.0 (E4M3), expect=9.0, read=E4M3",
        "read_mode": "0",
        "wm": [0]*9, "w": ["38"]*9, "wc": ["E4M3 1.0"]*9,
        "im": [0]*9, "i": ["38"]*9, "ic": ["E4M3 1.0"]*9,
    },
    {
        "name": "Test02: Single 2.0 x 3.0 (E4M3), rest=0, expect=6.0",
        "read_mode": "0",
        "wm": [0]*9,
        "w": ["40","00","00","00","00","00","00","00","00"],
        "wc": ["E4M3 2.0"] + ["zero"]*8,
        "im": [0]*9,
        "i": ["44","00","00","00","00","00","00","00","00"],
        "ic": ["E4M3 3.0"] + ["zero"]*8,
    },
    {
        "name": "Test03: All 2.0 x 2.0 (E4M3), expect=36.0",
        "read_mode": "0",
        "wm": [0]*9, "w": ["40"]*9, "wc": ["E4M3 2.0"]*9,
        "im": [0]*9, "i": ["40"]*9, "ic": ["E4M3 2.0"]*9,
    },

    # --- 부호 검증 ---
    {
        "name": "Test04: All 1.0 x (-1.0) (E4M3), expect=-9.0",
        "read_mode": "0",
        "wm": [0]*9, "w": ["38"]*9, "wc": ["E4M3 1.0"]*9,
        "im": [0]*9, "i": ["B8"]*9, "ic": ["E4M3 -1.0"]*9,
    },

    # --- E5M2 포맷 검증 ---
    {
        "name": "Test05: All 1.0 x 1.0 (E5M2), expect=9.0, read=E5M2",
        "read_mode": "1",
        "wm": [1]*9, "w": ["3C"]*9, "wc": ["E5M2 1.0"]*9,
        "im": [1]*9, "i": ["3C"]*9, "ic": ["E5M2 1.0"]*9,
    },

    # --- 소수점 / 대값 검증 ---
    {
        "name": "Test06: All 0.5 x 0.5 (E4M3), expect=2.25",
        "read_mode": "0",
        "wm": [0]*9, "w": ["30"]*9, "wc": ["E4M3 0.5"]*9,
        "im": [0]*9, "i": ["30"]*9, "ic": ["E4M3 0.5"]*9,
    },
    {
        "name": "Test07: All 4.0 x 4.0 (E4M3), expect=144.0 (overflow?)",
        "read_mode": "0",
        "wm": [0]*9, "w": ["48"]*9, "wc": ["E4M3 4.0"]*9,
        "im": [0]*9, "i": ["48"]*9, "ic": ["E4M3 4.0"]*9,
    },

    # --- Zero / 상쇄 검증 ---
    {
        "name": "Test08: +1/-1 cancel (E4M3), expect=0.0",
        "read_mode": "0",
        "wm": [0]*9, "w": ["38"]*9, "wc": ["E4M3 1.0"]*9,
        "im": [0]*9,
        "i": ["38","B8","38","B8","38","B8","38","B8","00"],
        "ic": ["1.0","-1.0","1.0","-1.0","1.0","-1.0","1.0","-1.0","zero"],
    },
    {
        "name": "Test09: All zero W and I (E4M3), expect=0.0",
        "read_mode": "0",
        "wm": [0]*9, "w": ["00"]*9, "wc": ["zero"]*9,
        "im": [0]*9, "i": ["00"]*9, "ic": ["zero"]*9,
    },

    # --- 읽기 모드 비교 ---
    {
        "name": "Test10: Original values, read=E4M3, expect=20.0",
        "read_mode": "0",
        "wm": [0,1,0,1,0,1,0,1,0],
        "w": ["38","40","30","3E","48","BC","3C","42","40"],
        "wc": ["E4M3 1.0","E5M2 2.0","E4M3 0.5","E5M2 1.5","E4M3 4.0","E5M2 -1.0","E4M3 1.5","E5M2 3.0","E4M3 2.0"],
        "im": [1,0,1,0,1,0,1,0,1],
        "i": ["42","30","40","40","3C","38","C0","44","3E"],
        "ic": ["E5M2 3.0","E4M3 0.5","E5M2 2.0","E4M3 2.0","E5M2 1.0","E4M3 1.0","E5M2 -2.0","E4M3 3.0","E5M2 1.5"],
    },
    {
        "name": "Test11: Original values, read=E5M2, expect=20.0",
        "read_mode": "1",
        "wm": [0,1,0,1,0,1,0,1,0],
        "w": ["38","40","30","3E","48","BC","3C","42","40"],
        "wc": ["E4M3 1.0","E5M2 2.0","E4M3 0.5","E5M2 1.5","E4M3 4.0","E5M2 -1.0","E4M3 1.5","E5M2 3.0","E4M3 2.0"],
        "im": [1,0,1,0,1,0,1,0,1],
        "i": ["42","30","40","40","3C","38","C0","44","3E"],
        "ic": ["E5M2 3.0","E4M3 0.5","E5M2 2.0","E4M3 2.0","E5M2 1.0","E4M3 1.0","E5M2 -2.0","E4M3 3.0","E5M2 1.5"],
    },

    # --- 누적 정밀도 검증 ---
    {
        "name": "Test12: All 1.5 x 1.5 (E4M3), expect=20.25",
        "read_mode": "0",
        "wm": [0]*9, "w": ["3C"]*9, "wc": ["E4M3 1.5"]*9,
        "im": [0]*9, "i": ["3C"]*9, "ic": ["E4M3 1.5"]*9,
    },
    {
        "name": "Test13: All 4.0 x 3.0 (E4M3), expect=108.0",
        "read_mode": "0",
        "wm": [0]*9, "w": ["48"]*9, "wc": ["E4M3 4.0"]*9,
        "im": [0]*9, "i": ["44"]*9, "ic": ["E4M3 3.0"]*9,
    },
    {
        "name": "Test14: All 1.0 x 2.0 (E4M3), expect=18.0",
        "read_mode": "0",
        "wm": [0]*9, "w": ["38"]*9, "wc": ["E4M3 1.0"]*9,
        "im": [0]*9, "i": ["40"]*9, "ic": ["E4M3 2.0"]*9,
    },

    # --- E5M2 입력 + E4M3 읽기 ---
    {
        "name": "Test15: All 1.0 x 2.0 (E5M2), read=E4M3, expect=18.0",
        "read_mode": "0",
        "wm": [1]*9, "w": ["3C"]*9, "wc": ["E5M2 1.0"]*9,
        "im": [1]*9, "i": ["40"]*9, "ic": ["E5M2 2.0"]*9,
    },
    {
        "name": "Test16: Single 3.0 x 3.0 (E4M3), read=E5M2, expect=9.0",
        "read_mode": "1",
        "wm": [0]*9,
        "w": ["44","00","00","00","00","00","00","00","00"],
        "wc": ["E4M3 3.0"] + ["zero"]*8,
        "im": [0]*9,
        "i": ["44","00","00","00","00","00","00","00","00"],
        "ic": ["E4M3 3.0"] + ["zero"]*8,
    },
]


# =====================================================================
#  실행
# =====================================================================

# 특정 테스트만 실행: python gen_tests.py 1 5 8
# 전체 실행:           python gen_tests.py
if len(sys.argv) > 1:
    selected = [int(x) - 1 for x in sys.argv[1:]]
    tests_to_run = [(idx, tests[idx]) for idx in selected if 0 <= idx < len(tests)]
else:
    tests_to_run = list(enumerate(tests))

pass_count = 0
fail_count = 0
results_summary = []

for idx, t in tests_to_run:
    # initial block 생성
    lines = []
    lines.append("initial begin")
    lines.append("    // --- READ mode ---")
    lines.append(f"    READ_MODE = 1'b{t['read_mode']};")
    lines.append("")
    for j in range(9):
        lines.append(f"    WM[{j}] = {t['wm'][j]};  W[{j}] = 8'h{t['w'][j]};  // {t['wc'][j]}")
    lines.append("")
    for j in range(9):
        lines.append(f"    IM[{j}] = {t['im'][j]};  I[{j}] = 8'h{t['i'][j]};  // {t['ic'][j]}")
    lines.append("end")
    replacement = "\n".join(lines)

    modified = pattern.sub(replacement, tb_original, count=1)

    tb_file = f"tb_test_{idx}.v"
    with open(tb_file, "w", encoding="utf-8") as f:
        f.write(modified)

    # 컴파일
    cmd_compile = f"iverilog -g2012 -o tb_test_{idx}.vvp {tb_file} {DESIGN_FILES}"
    r = subprocess.run(cmd_compile, shell=True, capture_output=True, text=True)
    if r.returncode != 0:
        print(f"\n{'='*64}")
        print(f"  {t['name']} -- COMPILE ERROR")
        print(r.stderr)
        fail_count += 1
        results_summary.append((t['name'], "COMPILE ERROR", "", "", ""))
        continue

    # 실행
    cmd_run = f"vvp tb_test_{idx}.vvp"
    r = subprocess.run(cmd_run, shell=True, capture_output=True, text=True, timeout=30)
    output = r.stdout

    print(f"\n{'='*64}")
    print(f"  {t['name']}")
    print("="*64)

    # 주요 라인 출력
    in_result = False
    expected_str = ""
    actual_str = ""
    error_str = ""
    for line in output.split("\n"):
        if "acc_done_flag" in line:
            print(line)
        if "acc_r_data" in line:
            print(line)
        if "SPI RX" in line:
            print(line)
        if "RESULT (READ" in line:
            in_result = True
        if in_result:
            print(line)
            if "Expected" in line:
                expected_str = line.strip()
            if "Actual" in line:
                actual_str = line.strip()
            if "Error" in line:
                error_str = line.strip()
                in_result = False

    # PASS/FAIL 판정
    error_val = 0.0
    try:
        error_val = float(error_str.split(":")[-1].strip())
    except:
        pass

    if abs(error_val) < 0.001:
        status = "PASS"
        pass_count += 1
    else:
        status = "** FAIL **"
        fail_count += 1
    print(f"\n  --> {status}")
    results_summary.append((t['name'], status, expected_str, actual_str, error_str))

    # 임시 파일 정리
    try:
        os.remove(tb_file)
        os.remove(f"tb_test_{idx}.vvp")
    except:
        pass

# VCD 정리
try:
    os.remove("tb_TOP.vcd")
except:
    pass

# =====================================================================
#  요약 테이블
# =====================================================================
print(f"\n{'='*64}")
print(f"  SUMMARY: {pass_count} PASS / {fail_count} FAIL / {pass_count+fail_count} TOTAL")
print("="*64)
for name, status, exp, act, err in results_summary:
    mark = "O" if status == "PASS" else "X"
    print(f"  [{mark}] {name}")
    if status != "PASS":
        print(f"       {exp}")
        print(f"       {act}")
        print(f"       {err}")
print()
