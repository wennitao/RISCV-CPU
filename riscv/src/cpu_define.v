`define Disable 1'b0
`define Enable 1'b1
`define Invalid 1'b0
`define Valid 1'b1
`define AddressBus 31:0
`define DataBus 31:0
`define RamDataBus 7:0
`define InstBus 31:0

`define PcStep 32'h4
`define AddressStep 32'h1

`define Read 1'b0
`define Write 1'b1

`define Null 0

//MemCtrl
`define StageBus 2:0
`define None 3'b000
`define StageOne 3'b001
`define StageTwo 3'b010
`define StageThree 3'b011
`define Done 3'b100
`define Step 3'b001

//InstCache
`define InstCacheSizeBus 511:0
`define InstCacheIndexBus 10:2
`define InstCacheTagBus 17:11
`define InstCacheTagLenBus 6:0

//InstructionQueue
`define IQLenBus 16
`define IQIdxBus 3:0