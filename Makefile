CXX=g++
CPP_FLAGS=-O3 -march=native -mtune=native -std=c++11 -fopenmp -mavx -g -Iinclude

SRC_DIR=src
INC_DIR=include
BLD_DIR=bin
MAT_DIR=data

BIN=$(BLD_DIR)/create-ttmat $(BLD_DIR)/create-ttvec $(BLD_DIR)/compare-ttvec $(BLD_DIR)/ttmatvec $(BLD_DIR)/ttmatvec-seq $(BLD_DIR)/ttmatvec-omp $(BLD_DIR)/ttmatvec-omptask

MAT=$(MAT_DIR)/ttmat.bin
VECX=$(MAT_DIR)/ttvecx.bin
VECY=$(MAT_DIR)/ttvecy.bin

all: $(BIN)

$(BLD_DIR)/ttmatvec: $(SRC_DIR)/ttmatvec.cpp $(SRC_DIR)/ttmat.cpp $(INC_DIR)/ttmat.h $(SRC_DIR)/ttvec.cpp $(INC_DIR)/ttvec.h
	mkdir -p $(BLD_DIR)
	$(CXX) $(CPP_FLAGS) $(SRC_DIR)/ttmatvec.cpp $(SRC_DIR)/ttmat.cpp $(SRC_DIR)/ttvec.cpp -lm -o $(BLD_DIR)/ttmatvec	

$(BLD_DIR)/ttmatvec-seq: $(SRC_DIR)/ttmatvec.cpp $(SRC_DIR)/ttmat-seq.cpp $(INC_DIR)/ttmat.h $(SRC_DIR)/ttvec.cpp $(INC_DIR)/ttvec.h
	mkdir -p $(BLD_DIR)
	$(CXX) $(CPP_FLAGS) $(SRC_DIR)/ttmatvec.cpp $(SRC_DIR)/ttmat-seq.cpp $(SRC_DIR)/ttvec.cpp -lm -o $(BLD_DIR)/ttmatvec-seq

$(BLD_DIR)/ttmatvec-omp: $(SRC_DIR)/ttmatvec.cpp $(SRC_DIR)/ttmat-omp.cpp $(INC_DIR)/ttmat.h $(SRC_DIR)/ttvec.cpp $(INC_DIR)/ttvec.h
	mkdir -p $(BLD_DIR)
	$(CXX) $(CPP_FLAGS) $(SRC_DIR)/ttmatvec.cpp $(SRC_DIR)/ttmat-omp.cpp $(SRC_DIR)/ttvec.cpp -lm -o $(BLD_DIR)/ttmatvec-omp

$(BLD_DIR)/ttmatvec-omptask: $(SRC_DIR)/ttmatvec.cpp $(SRC_DIR)/ttmat-omptask.cpp $(INC_DIR)/ttmat.h $(SRC_DIR)/ttvec.cpp $(INC_DIR)/ttvec.h
	mkdir -p $(BLD_DIR)
	$(CXX) $(CPP_FLAGS) $(SRC_DIR)/ttmatvec.cpp $(SRC_DIR)/ttmat-omptask.cpp $(SRC_DIR)/ttvec.cpp -lm -o $(BLD_DIR)/ttmatvec-omptask

$(BLD_DIR)/create-ttmat: $(SRC_DIR)/create-ttmat.cpp
	mkdir -p $(BLD_DIR)
	$(CXX) $(CPP_FLAGS) $(SRC_DIR)/create-ttmat.cpp -o $(BLD_DIR)/create-ttmat

$(BLD_DIR)/create-ttvec: $(SRC_DIR)/create-ttvec.cpp
	mkdir -p $(BLD_DIR)
	$(CXX) $(CPP_FLAGS) $(SRC_DIR)/create-ttvec.cpp -o $(BLD_DIR)/create-ttvec

$(BLD_DIR)/compare-ttvec: $(SRC_DIR)/compare-ttvec.cpp $(SRC_DIR)/ttvec.cpp
	mkdir -p $(BLD_DIR)
	$(CXX) $(CPP_FLAGS) $(SRC_DIR)/compare-ttvec.cpp $(SRC_DIR)/ttvec.cpp -lm -o $(BLD_DIR)/compare-ttvec

$(MAT): create-ttmat
	$(BLD_DIR)/create-ttmat -f $(MAT) -d 3 -m 100,99,87 -n 199,47,133 -r 25,25

$(VECX): create-ttvec
	$(BLD_DIR)/create-ttvec -f $(VECX) -d 3 -m 100,99,87 -r 25,25

$(VECY): ttmatvec $(VECX) $(MAT)
	$(BLD_DIR)/ttmatvec -a $(MAT) -x $(VECX) -y $(VECY)

.PHONY: create-data
create-data: $(MAT) $(VECX) $(VECY)

test: test-seq test-omp test-omptask

test-seq: ttmatvec-seq compare-ttvec create-data
	echo "Sequential"
	@$(BLD_DIR)/ttmatvec-seq -a $(MAT) -x $(VECX) -y $(MAT_DIR)/ttvecy_seq.bin
	@$(BLD_DIR)/compare-ttvec -x $(MAT_DIR)/ttvecy_seq.bin -y $(VECY)

test-omp: ttmatvec-omp compare-ttvec create-data
	echo "OpenMP"
	@$(BLD_DIR)/ttmatvec-omp -a $(MAT) -x $(VECX) -y $(MAT_DIR)/ttvecy_omp.bin
	@$(BLD_DIR)/compare-ttvec -x $(MAT_DIR)/ttvecy_omp.bin -y $(VECY)

test-omptask: ttmatvec-omptask compare-ttvec create-data
	echo "OpenMP Tasks"
	@$(BLD_DIR)/ttmatvec-omptask -a $(MAT) -x $(VECX) -y $(MAT_DIR)/ttvecy_omptask.bin
	@$(BLD_DIR)/compare-ttvec -x $(MAT_DIR)/ttvecy_omptask.bin -y $(VECY)

perf: perf-seq perf-omp perf-omptask

perf-seq: $(BIN) create-data
	$(BLD_DIR)/ttmatvec-seq -a $(MAT) -x $(VECX) -y $(MAT_DIR)/ttvecy_seq.bin

perf-omp: $(BIN) create-data
	$(BLD_DIR)/ttmatvec-omp -a $(MAT) -x $(VECX) -y $(MAT_DIR)/ttvecy_omp.bin

perf-omptask: $(BIN) create-data
	$(BLD_DIR)/ttmatvec-omptask -a $(MAT) -x $(VECX) -y $(MAT_DIR)/ttvecy_omptask.bin

#### OTHER ####
clean:
	rm -f $(BLD_DIR)/* $(MAT_DIR)/*

