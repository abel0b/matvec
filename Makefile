CXX=g++
CPP_FLAGS=-march=native -mtune=native -std=c++11 -Iinclude -lm
NUM_THREADS=20
SOURCE_DIR=src
INCLUDE_DIR=include
BINARY_DIR=build
MAT=$(BINARY_DIR)/ttmat.bin
VECX=$(BINARY_DIR)/ttvecx.bin
VECY=$(BINARY_DIR)/ttvecy.bin
N=1024
R=8

.PHONY: all
all: makedirs $(BINARY_DIR)/create-ttmat $(BINARY_DIR)/create-ttvec $(BINARY_DIR)/compare-ttvec $(BINARY_DIR)/ttmatvec $(BINARY_DIR)/ttmatvec-baseline $(BINARY_DIR)/ttmatvec-seq $(BINARY_DIR)/ttmatvec-omp $(BINARY_DIR)/ttmatvec-omptask $(MAT) $(VECX) $(VECY)
	
.PHONY: makedirs
makedirs:
	mkdir -p $(BINARY_DIR)

# Compile versions
$(BINARY_DIR)/ttmatvec: $(SOURCE_DIR)/ttmatvec.cpp $(SOURCE_DIR)/ttmat.cpp $(INCLUDE_DIR)/ttmat.h $(SOURCE_DIR)/ttvec.cpp $(INCLUDE_DIR)/ttvec.h
	$(CXX) $(CPP_FLAGS) $^ -o $@

$(BINARY_DIR)/ttmatvec-baseline: $(SOURCE_DIR)/ttmatvec.cpp $(SOURCE_DIR)/ttmat.cpp $(INCLUDE_DIR)/ttmat.h $(SOURCE_DIR)/ttvec.cpp $(INCLUDE_DIR)/ttvec.h
	$(CXX) $(CPP_FLAGS) -O3 -mavx $^ -o $@

$(BINARY_DIR)/ttmatvec-seq: $(SOURCE_DIR)/ttmatvec.cpp $(SOURCE_DIR)/ttmat-seq.cpp $(INCLUDE_DIR)/ttmat.h $(SOURCE_DIR)/ttvec.cpp $(INCLUDE_DIR)/ttvec.h
	$(CXX) $(CPP_FLAGS) -DOPTI_INLINE -O3 -mavx $^ -o $@

$(BINARY_DIR)/ttmatvec-omp: $(SOURCE_DIR)/ttmatvec.cpp $(SOURCE_DIR)/ttmat-omp.cpp $(INCLUDE_DIR)/ttmat.h $(SOURCE_DIR)/ttvec.cpp $(INCLUDE_DIR)/ttvec.h
	$(CXX) $(CPP_FLAGS) -DOPTI_INLINE -O3 -mavx -fopenmp $^ -o $@

$(BINARY_DIR)/ttmatvec-omptask: $(SOURCE_DIR)/ttmatvec.cpp $(SOURCE_DIR)/ttmat-omptask.cpp $(INCLUDE_DIR)/ttmat.h $(SOURCE_DIR)/ttvec.cpp $(INCLUDE_DIR)/ttvec.h
	$(CXX) $(CPP_FLAGS) -DOPTI_INLINE -O3 -mavx -fopenmp $^ -o $@

$(BINARY_DIR)/create-ttmat: $(SOURCE_DIR)/create-ttmat.cpp
	$(CXX) $(CPP_FLAGS) -O3 -mavx $^ -o $@

$(BINARY_DIR)/create-ttvec: $(SOURCE_DIR)/create-ttvec.cpp
	$(CXX) $(CPP_FLAGS) -O3 -mavx $^ -o $@

$(BINARY_DIR)/compare-ttvec: $(SOURCE_DIR)/compare-ttvec.cpp $(SOURCE_DIR)/ttvec.cpp
	$(CXX) $(CPP_FLAGS) -O3 -mavx $^ -o $@

# Create data
$(MAT): $(BINARY_DIR)/create-ttmat
	$(BINARY_DIR)/create-ttmat -f $(MAT) -d 3 -m $(N),$(N),$(N) -n $(N),$(N),$(N) -r $(R),$(R)

$(VECX): $(BINARY_DIR)/create-ttvec
	$(BINARY_DIR)/create-ttvec -f $(VECX) -d 3 -m $(N),$(N),$(N) -r $(R),$(R)

$(VECY): $(BINARY_DIR)/ttmatvec $(VECX) $(MAT)
	$(BINARY_DIR)/ttmatvec -a $(MAT) -x $(VECX) -y $(VECY)


# Run tests
.PHONY: test
test: test-seq test-omp test-omptask

.PHONY: test-seq
test-seq: $(BINARY_DIR)/ttmatvec-seq $(BINARY_DIR)/compare-ttvec $(MAT) $(VECX) $(VECY)
	$(BINARY_DIR)/ttmatvec-seq -a $(MAT) -x $(VECX) -y $(BINARY_DIR)/ttvecy_seq.bin
	$(BINARY_DIR)/compare-ttvec -x $(BINARY_DIR)/ttvecy_seq.bin -y $(VECY)

.PHONY: test-omp
test-omp: $(BINARY_DIR)/ttmatvec-omp $(BINARY_DIR)/compare-ttvec $(MAT) $(VECX) $(VECY)
	$(BINARY_DIR)/ttmatvec-omp -a $(MAT) -x $(VECX) -y $(BINARY_DIR)/ttvecy_omp.bin
	$(BINARY_DIR)/compare-ttvec -x $(BINARY_DIR)/ttvecy_omp.bin -y $(VECY)

.PHONY: test-omptask
test-omptask: $(BINARY_DIR)/ttmatvec-omptask $(BINARY_DIR)/compare-ttvec $(MAT) $(VECX) $(VECY) 
	$(BINARY_DIR)/ttmatvec-omptask -a $(MAT) -x $(VECX) -y $(BINARY_DIR)/ttvecy_omptask.bin
	$(BINARY_DIR)/compare-ttvec -x $(BINARY_DIR)/ttvecy_omptask.bin -y $(VECY)

# Run benchmarks
.PHONY: bench
bench: $(BINARY_DIR)/ttmatvec $(BINARY_DIR)/ttmatvec-seq $(BINARY_DIR)/ttmatvec-omp $(BINARY_DIR)/ttmatvec-omptask $(MAT) $(VECX)
	MAT=$(MAT) VECX=$(VECX) BINARY_DIR=$(BINARY_DIR) ./bench/speedup.sh
	MAT=$(MAT) VECX=$(VECX) BINARY_DIR=$(BINARY_DIR) ./bench/amdal.sh

# Clean built files
.PHONY: clean
clean:
	rm -rf $(BINARY_DIR)/*

