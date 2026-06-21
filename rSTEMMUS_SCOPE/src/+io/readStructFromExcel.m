function data = readStructFromExcel(filename, sheetName, headerIdx, dataIdx, data_is_char, data_in_rows)
    % Read data into a struct with names matching those found in the first column/row
    %  default is for data to be in columns (A and B); if data_in_rows = true, data are in rows 1 & 2
    %  example:
    %   readStructFromExcel('../input_data.xlsx', 'options', 3, 1)
    %   readStructFromExcel('../input_data.xlsx', 'filenames', 1, 2, true)
    %
    % UPDATED 2026-01-28: Added cross-platform support using readtable() for
    % MATLAB on Mac/Linux where xlsread() may not work without toolbox.

    % default values:
    if nargin < 3
        headerIdx = 1;
    end
    if nargin < 4
        dataIdx = 2;
    end
    if nargin < 5
        data_is_char = false;
    end
    if nargin < 6
        data_in_rows = false;
    end

    % Check if we're running in Octave or MATLAB
    isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;
    
    if isOctave
        % Octave: On Windows, the io package's xlsread calls xlsopen which
        % invokes the system 'unzip' binary. When unzip is missing, xlsopen
        % crashes at the C-level, bypassing MATLAB-level try/catch entirely.
        % UPDATED 2026-06-02: Skip xlsread completely on Windows Octave and
        %   go directly to readXlsxNative (tar-based parser). This avoids
        %   the un-catchable xlsopen crash. See Contribution #42.
        isWin = ispc();
        if isWin
            % Windows Octave: go directly to native parser (tar-based)
            allCells = io.readXlsxNative(filename, sheetName);
            if ~data_in_rows
                allCells = allCells';
            end
        else
            % Non-Windows Octave: try xlsread first, fallback to native
            try
                if data_in_rows
                    [~, ~, allCells] = xlsread(filename, sheetName);
                else
                    [~, ~, allCells] = xlsread(filename, sheetName);
                    allCells = allCells';
                end
            catch ME
                warning('Octave xlsread failed (%s), trying native xlsx parser...', ME.message);
                allCells = io.readXlsxNative(filename, sheetName);
                if ~data_in_rows
                    allCells = allCells';
                end
            end
        end
    else
        % MATLAB: Try readtable first (works on Mac without toolbox)
        try
            % Use readtable which is more reliable across platforms
            opts = detectImportOptions(filename, 'Sheet', sheetName);
            opts.VariableNamingRule = 'preserve';
            opts.DataRange = 'A1';
            T = readtable(filename, opts, 'Sheet', sheetName);
            
            % Convert table to cell array
            allCells = [T.Properties.VariableNames; table2cell(T)];
            
            if ~data_in_rows
                allCells = allCells';
            end
        catch ME
            % Fall back to xlsread if readtable fails
            warning('readtable failed, trying xlsread: %s', ME.message);
            try
                if data_in_rows
                    [~, ~, allCells] = xlsread(filename, sheetName);
                else
                    [~, ~, allCells] = xlsread(filename, sheetName);
                    allCells = allCells';
                end
            catch ME2
                error('Cannot read Excel file. On Mac, ensure you have a compatible file format.\nError: %s', ME2.message);
            end
        end
    end
    
    % data are now in columns

    % delete empty columns
    % define two "helper functions" for eliminating null entries
    isNotNumeric = @(x) cellfun(@(y) ischar(y) | any(isnan(y)), x);
    isCharCell = @(x) cellfun(@(y) ischar(y), x);

    validHeaders = arrayfun(isCharCell, allCells(headerIdx, :));
    if data_is_char
        validData = arrayfun(isCharCell, allCells(dataIdx, :));
    else
        validData = ~arrayfun(isNotNumeric, allCells(dataIdx, :));
    end

    dataCells = allCells([headerIdx, dataIdx], validHeaders & validData);

    for idx = 1:size(dataCells, 2)
        varName = strrep(dataCells{1, idx}, ' ', '');
        data.(varName) = dataCells{2, idx};
    end
end
