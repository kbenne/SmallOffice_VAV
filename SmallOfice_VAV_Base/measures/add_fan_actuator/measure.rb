# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class AddFanActuator < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Add Fan Actuator'
  end

  # human readable description
  def description
    return 'Add a fan air speed actuator and it available to Alfalfa by following appropriate conventions'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Add a fan air speed actuator and it available to Alfalfa by following appropriate conventions'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    return args
  end

  def add_actuator_for_fan(vav_fan)
    model = vav_fan.model()

    actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(vav_fan, 'Fan', 'Fan Air Mass Flow Rate')
    fan_flow_global = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, vav_fan.nameString().gsub(' ','_') + '_Mass_Flow')
    fan_flow_global_enable = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, vav_fan.nameString().gsub(' ','_') + '_Mass_Flow_Enable')
    begin
      fan_flow_global.setExportToBCVTB(true)
      fan_flow_global_enable.setExportToBCVTB(true)
    rescue
     puts 'This version of OpenStudio does not support exporting ems globals to BCVTB' 
    end

    program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    program.addLine("IF #{fan_flow_global_enable.handle()} == 1")
    program.addLine("SET #{actuator.handle()} = #{fan_flow_global.handle()}")
    program.addLine("ELSE")
    program.addLine("SET #{actuator.handle()} = Null")
    program.addLine("ENDIF")

    manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    manager.setCallingPoint('AfterPredictorAfterHVACManagers')
    manager.addProgram(program)
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    fans = model.getFanVariableVolumes
    fans.each do |fan|
      add_actuator_for_fan(fan) 
    end

    return true
  end
end

# register the measure to be used by the application
AddFanActuator.new.registerWithApplication

