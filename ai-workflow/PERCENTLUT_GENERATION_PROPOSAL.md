# 🔧 **PercentLut Package Generation Proposal**

## 🎯 **Executive Summary**

Based on the DATADEF analysis, this document proposes a programmatic approach to create (or recreate) the PercentLut package using standardized templates and configuration-driven generation. This approach ensures consistency, maintainability, and Verilog portability while reducing manual coding errors.

## 📊 **Current PercentLut Analysis**

### **Existing Implementation Strengths**
- ✅ Comprehensive validation with bounds checking
- ✅ CRC-16 validation for data integrity
- ✅ Dual interface (array-based and record-based)
- ✅ Safe lookup functions with clamping
- ✅ Clear Verilog conversion documentation

### **Areas for Standardization**
- 🔄 Validation function naming patterns
- 🔄 Error handling consistency
- 🔄 Testbench structure standardization
- 🔄 Automated Verilog compatibility verification

## 🚀 **Proposed Generation Approach**

### **1. Configuration-Driven Generation**

Create a YAML configuration file that defines the PercentLut package structure:

```yaml
# percentlut_config.yaml
package_name: "PercentLut_pkg"
description: "PercentLut datatype with CRC validation and safe lookup functions"

# System constants
constants:
  - name: "SYSTEM_PERCENT_LUT_SIZE"
    value: 101
    description: "Indices 0-100"
    type: "natural"
  
  - name: "SYSTEM_PERCENT_LUT_INDEX_WIDTH"
    value: 7
    description: "7 bits to address 0-100"
    type: "natural"
  
  - name: "SYSTEM_PERCENT_LUT_DATA_WIDTH"
    value: 16
    description: "16-bit unsigned data"
    type: "natural"
  
  - name: "SYSTEM_PERCENT_LUT_CRC_WIDTH"
    value: 16
    description: "CRC-16"
    type: "natural"
  
  - name: "SYSTEM_CRC16_POLYNOMIAL"
    value: "0x1021"
    description: "CRC-16-CCITT: x^16 + x^12 + x^5 + 1"
    type: "std_logic_vector"
    width: 16
  
  - name: "SYSTEM_CRC16_INIT_VALUE"
    value: "0xFFFF"
    description: "CRC-16 initial value"
    type: "std_logic_vector"
    width: 16

# Data structures
data_structures:
  - name: "percent_lut_data_array_t"
    type: "array"
    element_type: "std_logic_vector"
    element_width: "SYSTEM_PERCENT_LUT_DATA_WIDTH"
    size: "SYSTEM_PERCENT_LUT_SIZE"
    description: "Array of 16-bit LUT data values"
  
  - name: "percent_lut_record_t"
    type: "record"
    fields:
      - name: "data_array"
        type: "percent_lut_data_array_t"
        description: "The actual LUT data"
      
      - name: "crc"
        type: "std_logic_vector"
        width: "SYSTEM_PERCENT_LUT_CRC_WIDTH"
        description: "CRC validation"
      
      - name: "valid"
        type: "std_logic"
        description: "Validity flag"
      
      - name: "size"
        type: "std_logic_vector"
        width: "SYSTEM_PERCENT_LUT_INDEX_WIDTH"
        description: "Current size (0-100)"

# Default values
defaults:
  - name: "SYSTEM_PERCENT_LUT_RECORD_DEFAULT"
    type: "percent_lut_record_t"
    value:
      data_array: "(others => (others => '0'))"
      crc: "(others => '0')"
      valid: "'0'"
      size: "(others => '0')"

# Required functions
required_functions:
  validation:
    - name: "calculate_percent_lut_crc"
      description: "Calculate CRC for LUT data array"
      parameters:
        - name: "lut_data"
          type: "percent_lut_data_array_t"
      return_type: "std_logic_vector"
      return_width: "SYSTEM_PERCENT_LUT_CRC_WIDTH"
    
    - name: "validate_percent_lut"
      description: "Validate LUT data against CRC"
      parameters:
        - name: "lut_data"
          type: "percent_lut_data_array_t"
        - name: "lut_crc"
          type: "std_logic_vector"
          width: "SYSTEM_PERCENT_LUT_CRC_WIDTH"
      return_type: "boolean"
    
    - name: "validate_percent_lut_record"
      description: "Validate complete LUT record"
      parameters:
        - name: "lut_rec"
          type: "percent_lut_record_t"
      return_type: "boolean"
    
    - name: "is_percent_lut_record_valid"
      description: "Check if LUT record is valid"
      parameters:
        - name: "lut_rec"
          type: "percent_lut_record_t"
      return_type: "boolean"

  safe_access:
    - name: "get_percentlut_value_safe"
      description: "Safe lookup with bounds checking and clamping"
      overloads:
        - parameters:
            - name: "lut_rec"
              type: "percent_lut_record_t"
            - name: "index"
              type: "std_logic_vector"
              width: 7
          return_type: "std_logic_vector"
          return_width: "SYSTEM_PERCENT_LUT_DATA_WIDTH"
        
        - parameters:
            - name: "lut_rec"
              type: "percent_lut_record_t"
            - name: "index"
              type: "natural"
          return_type: "std_logic_vector"
          return_width: "SYSTEM_PERCENT_LUT_DATA_WIDTH"
        
        - parameters:
            - name: "lut_data"
              type: "percent_lut_data_array_t"
            - name: "index"
              type: "std_logic_vector"
              width: 7
          return_type: "std_logic_vector"
          return_width: "SYSTEM_PERCENT_LUT_DATA_WIDTH"
        
        - parameters:
            - name: "lut_data"
              type: "percent_lut_data_array_t"
            - name: "index"
              type: "natural"
          return_type: "std_logic_vector"
          return_width: "SYSTEM_PERCENT_LUT_DATA_WIDTH"

  utilities:
    - name: "is_valid_percent_lut_index"
      description: "Validate LUT index"
      overloads:
        - parameters:
            - name: "index"
              type: "std_logic_vector"
          return_type: "boolean"
        
        - parameters:
            - name: "index"
              type: "natural"
          return_type: "boolean"
    
    - name: "create_percent_lut_record"
      description: "Create LUT record from data array"
      parameters:
        - name: "lut_data"
          type: "percent_lut_data_array_t"
      return_type: "percent_lut_record_t"
    
    - name: "create_percent_lut_record_with_crc"
      description: "Create LUT record with calculated CRC"
      parameters:
        - name: "lut_data"
          type: "percent_lut_data_array_t"
      return_type: "percent_lut_record_t"

# Verilog conversion
verilog_conversion:
  target: "SystemVerilog"
  strategy:
    - "Records -> flattened structs with explicit field access"
    - "Array types -> parameter arrays or memory initialization files (.mem)"
    - "CRC functions -> separate Verilog modules or SystemVerilog functions"
    - "Function overloading -> renamed functions for clarity"
    - "Record access -> explicit field access (e.g., lut.data_array[index])"
  
  bit_layouts:
    data_array: "0 to SYSTEM_PERCENT_LUT_SIZE-1 of SYSTEM_PERCENT_LUT_DATA_WIDTH-1 downto 0"
    crc: "SYSTEM_PERCENT_LUT_CRC_WIDTH-1 downto 0"
    valid: "single bit"
    size: "SYSTEM_PERCENT_LUT_INDEX_WIDTH-1 downto 0"

# Testbench requirements
testbench:
  required_tests:
    - "CRC calculation validation"
    - "Bounds checking and clamping"
    - "Record validation"
    - "Safe lookup functions"
    - "Index validation"
    - "Record creation and manipulation"
  
  test_patterns:
    - "Linear data (0, 1, 2, ...)"
    - "Pattern-based data"
    - "Edge cases (0, 100, invalid indices)"
    - "Invalid data scenarios"
```

### **2. Template-Based Generation**

Create standardized VHDL templates that can be populated from the configuration:

#### **Package Header Template**
```vhdl
-- Package: {{package_name}}
-- Purpose: {{description}}
-- Generated: {{generation_date}}
-- 
-- DATADEF PACKAGE: This package defines data structures using records for better
-- encapsulation and type safety.
-- 
-- VERILOG CONVERSION STRATEGY:
{{#verilog_conversion.strategy}}
-- - {{.}}
{{/verilog_conversion.strategy}}

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

{{#dependencies}}
-- Import {{name}} for {{purpose}}
use work.{{name}}.all;
{{/dependencies}}

package {{package_name}} is
```

#### **Constants Template**
```vhdl
    -- Data Definition Constants (SYSTEM_* prefix for system parameters)
{{#constants}}
    constant {{name}} : {{type}} := {{value}}; -- {{description}}
{{/constants}}
```

#### **Data Types Template**
```vhdl
    -- {{description}}
    type {{name}} is {{#type}}{{#array}}array (0 to {{size}}-1) of {{element_type}}({{element_width}}-1 downto 0){{/array}}{{#record}}record{{#fields}}
        {{name}} : {{type}};  -- {{description}}{{/fields}}
    end record{{/record}}{{/type}};
```

#### **Default Values Template**
```vhdl
    -- Default/initialization values for the record
    constant {{name}} : {{type}} := (
{{#value}}
        {{name}} => {{value}}{{^last}},{{/last}}
{{/value}}
    );
```

#### **Function Templates**
```vhdl
    -- {{description}}
    function {{name}}({{#parameters}}{{name}} : {{type}}{{^last}}; {{/last}}{{/parameters}}) return {{return_type}};
```

### **3. Generation Pipeline**

#### **Step 1: Configuration Validation**
```python
def validate_config(config_file):
    """Validate YAML configuration against schema"""
    # Check required fields
    # Validate data types
    # Ensure consistency
    pass
```

#### **Step 2: Template Population**
```python
def generate_package(config, templates):
    """Generate VHDL package from configuration and templates"""
    # Load templates
    # Populate with configuration data
    # Generate VHDL code
    pass
```

#### **Step 3: Code Generation**
```python
def generate_vhdl_code(config):
    """Generate complete VHDL package"""
    # Generate package header
    # Generate constants
    # Generate data types
    # Generate functions
    # Generate package body
    pass
```

#### **Step 4: Testbench Generation**
```python
def generate_testbench(config):
    """Generate comprehensive testbench"""
    # Generate test entity
    # Generate test procedures
    # Generate test cases
    # Generate validation logic
    pass
```

## 🔄 **Recreation vs. Improvement Strategy**

### **Option 1: Complete Recreation**
- Generate entirely new package from configuration
- Ensure 100% compliance with new standards
- Risk: May lose existing optimizations or edge cases

### **Option 2: Incremental Improvement**
- Analyze existing package against new standards
- Generate only missing or non-compliant sections
- Preserve existing working code
- Risk: May maintain some inconsistencies

### **Option 3: Hybrid Approach (Recommended)**
- Generate new package structure
- Migrate existing function implementations
- Validate and improve existing code
- Ensure full compliance with new standards

## 📋 **Implementation Plan**

### **Phase 1: Template Development (Week 1)**
- [ ] Create YAML configuration schema
- [ ] Develop VHDL package templates
- [ ] Create function generation templates
- [ ] Develop testbench templates

### **Phase 2: Generation Engine (Week 2)**
- [ ] Implement configuration parser
- [ ] Create template engine
- [ ] Develop VHDL code generator
- [ ] Add validation and error checking

### **Phase 3: PercentLut Generation (Week 3)**
- [ ] Create PercentLut configuration
- [ ] Generate new package
- [ ] Validate against existing functionality
- [ ] Generate comprehensive testbench

### **Phase 4: Testing and Validation (Week 4)**
- [ ] Run existing tests against new package
- [ ] Verify Verilog compatibility
- [ ] Performance comparison
- [ ] Documentation updates

## 🎯 **Expected Benefits**

### **Immediate Benefits**
- **Consistency**: All generated packages follow identical patterns
- **Maintainability**: Changes to standards update all packages
- **Documentation**: Automatic generation of conversion guides
- **Testing**: Standardized testbench structure

### **Long-term Benefits**
- **Scalability**: Easy creation of new datadef packages
- **Quality**: Reduced manual coding errors
- **Standards**: Enforced compliance with datadef standards
- **Automation**: Reduced development time for new packages

## 🔍 **Risk Assessment**

### **Technical Risks**
- **Template Complexity**: Complex templates may be hard to maintain
- **Configuration Errors**: Invalid configurations could generate broken code
- **Performance**: Generated code may not be as optimized as hand-written

### **Mitigation Strategies**
- **Simple Templates**: Keep templates focused and readable
- **Validation**: Comprehensive configuration validation
- **Testing**: Extensive testing of generated code
- **Fallback**: Maintain ability to hand-edit generated code

## 🚀 **Next Steps**

1. **Review Proposal**: Validate this approach against your requirements
2. **Template Development**: Start with simple, focused templates
3. **Proof of Concept**: Generate a simple datadef package as validation
4. **Iterative Improvement**: Refine templates based on results
5. **Full Implementation**: Complete the generation system

---

*This proposal provides a roadmap for creating a robust, maintainable datadef generation system that can scale with your project needs while ensuring consistency and quality.*
