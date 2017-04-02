ProcessConfig = require '../process-config'
SaveController = require './save-controller'
ConfigController = require './config-controller'
ProcessController = require './process-controller'
RegExpPattern = require '../pattern/regexp-pattern'
PathPattern = require '../pattern/path-pattern'
{Directory, File, BufferedProcess, CompositeDisposable} = require 'atom'
os = require 'os';

module.exports =
class ProjectController

  constructor: (@main, @projectPath) ->
    @configControllers = [];
    @saveControllers = [];
    @patterns = {};
    @configurationFile = new Directory(@projectPath).getFile('process-palette.json');
    @processConfigs = {};
    @global = null;
    @projectName = null;
    @loadFile();

  getMain: ->
    return @main;

  getConfigControllers: ->
    return @configControllers;

  isGlobal: ->
    if @global == null
      configFile = new File(atom.config.getUserConfigPath());
      @global = @projectPath == configFile.getParent().getRealPathSync();

    return @global;

  getProjectName: ->
    if @projectName == null
      dir = new Directory(@projectPath);
      @projectName = dir.getBaseName();

    return @projectName;

  getProjectPath: ->
    return @projectPath;

  getConfigurationFile: ->
    return @configurationFile;

  dispose: ->
    @clearControllers();

  clearControllers: ->
    @clearConfigControllers();
    @clearSaveControllers();

  clearConfigControllers: ->
    for configController in @configControllers
      @main.mainView.removeConfigController(configController);
      configController.dispose();

    @configControllers = [];

  clearSaveControllers: ->
    for saveController in @saveControllers
      saveController.dispose();

    @saveControllers = [];

  saveFile: ->
    # A ProjectController is created for each project, but that doesn't mean that
    # it has a configuration file. Only save if there is actually a file, otherwise
    # an empty file will be created.
    if @configurationFile.existsSync()
      text = JSON.stringify(@processConfigs, null, '  ')
      @configurationFile.writeSync(text);

  loadFile: ->
    @clearControllers();

    if (!@configurationFile.isFile() or !@configurationFile.existsSync())
      return;

    @configurationFile.read(true).then (resolve) =>
      @parseFile(resolve);

  parseFile: (content) ->
    try
      @processConfigs = JSON.parse(content);
    catch err
      console.log("error");
      console.log(err.lineNumber);
      return;

    if !@processConfigs?
      return;

    @addDefaultPattern();

    if not @processConfigs.defaultPatterns?
      @processConfigs.defaultPatterns = []

    for key in @processConfigs.defaultPatterns
      if not key of @processConfigs.patterns
        @processConfigs.defaultPatterns.remove key

    if @processConfigs.patterns?
      for key, value of @processConfigs.patterns
        @addPattern(key, value);
        if not key in @processConfigs.defaultPatterns
          @processConfigs.defaultPatterns.push key

    if @processConfigs.commands?
      commands = @processConfigs.commands.slice();
      @processConfigs.commands = [];

      for command in commands
        command = new ProcessConfig(command);
        @processConfigs.commands.push(command);

        if command.isValid()
          configController = new ConfigController(@, command);
          @configControllers.push(configController);
          @main.mainView.addConfigController(configController);

    if @processConfigs.saveCommands?
      for saveCommand in @processConfigs.saveCommands
        saveController = new SaveController(@main, saveCommand);
        @saveControllers.push(saveController);

  getPatterns: (names) ->
    result = [];

    if !names?
      return result;

    for name in names
      pattern = @patterns[name];

      if pattern
        result.push(pattern);

    return result;

  addDefaultPattern: ->
    config = {};
    config.expression = "(path)";
    @addPattern("default", config);

  addPattern: (name, config) ->
    pattern = @createPattern(name, config);

    if pattern != null
      @patterns[name] = pattern;

  createPattern: (name, config) ->
    # Make a copy so that the original doesn't get modified.
    config = JSON.parse(JSON.stringify(config));
    config.name = name

    if !config.expression?
      console.error("Pattern #{name} doesn't have an expression.")
      return null;

    if !config.flags?
      config.flags = "i";

    #config.flags += "x" if config.expression.indexOf("\n") >= 0  # not available in stadard javascript regexp
    config.isLineExpression = config.expression.indexOf("^") == 0
    config.isPathExpression = config.expression.indexOf("(path)") >= 0
    config.isInlineExpression = not config.isLineExpression and not config.isPathExpression

    if config.isPathExpression
      pathIndex = config.expression.indexOf("(path)");
      lineIndex = config.expression.indexOf("(line)");

      config.pathIndex = 1;

      if lineIndex > -1
        if pathIndex < lineIndex
          config.lineIndex = 2;
        else
          config.lineIndex = 1;
          config.pathIndex = 2;

      if !config.path?
        config.path = @getPathExpression(lineIndex > -1);

      config.expression = config.expression.replace("(path)", "(" + config.path + ")");
      config.expression = config.expression.replace("(line)", "(\\d+)");
      config.expression = config.expression.replace(/\n/g, ""); # cheap solution to missing x-flag

      try
        return new PathPattern(config);
      catch err
        console.error("Pattern #{name} (Path) could not be created.");
        console.error(err);

    else

      try
        return new RegExpPattern(config);
      catch err
        console.error("Pattern #{name} (RegExp) could not be created.");
        console.error(err);

    return null;

  getPathExpression: (hasLine) ->
    if os.platform == "win32"
      return "(?:[a-z]:\\\\|\\\\)?[\\w\\.\\-\\\\]+[.\\\\][\\w\\.\\-\\\\]+";
    return "(?:~\\/|\\/)?[\\w\\.\\-\\/]+[.\\/][\\w\\.\\-\\/]+";

  editConfiguration: ->
    if (@configurationFile.isFile() and @configurationFile.existsSync())
      atom.workspace.open(@configurationFile.getPath());

  fileSaved: (path) =>
    for saveController in @saveControllers
      saveController.fileSaved(path);

  getConfigController: (namespace, action) =>
    for configController in @configControllers
      if (configController.config.namespace == namespace) and (configController.config.action == action)
        return configController;

    return null;
