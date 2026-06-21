function allCells = readXlsxNative(filename, sheetName)
    % readXlsxNative  Read an xlsx sheet into a cell array using only Octave builtins.
    %
    %   allCells = readXlsxNative(filename, sheetName)
    %
    %   This function is a fallback for Octave on Windows when the io package's
    %   xlsread() fails because the system 'unzip' binary is not on PATH.
    %   It uses Windows' built-in tar.exe (available on Windows 10+) to extract
    %   the xlsx archive, then parses the XML inside to reconstruct cell data.
    %
    %   An .xlsx file is a ZIP archive containing:
    %     xl/sharedStrings.xml  - shared string table (text values)
    %     xl/worksheets/sheet*.xml - cell data with row/col references
    %     xl/workbook.xml - sheet name <-> sheet file mapping
    %
    %   INPUTS:
    %     filename   - Path to .xlsx file
    %     sheetName  - Name of the sheet to read (e.g., 'options', 'filenames')
    %
    %   OUTPUT:
    %     allCells   - Cell array of all values (strings and numbers),
    %                  same format as xlsread's 3rd output argument.
    %
    %   UPDATED: 2026-05-21 (Contribution #42 fix for Windows unzip issue)
    %   AUTHORS: Arman Shirzad, EcoExtreML Contributors

    % Create temp directory for extraction
    tmpdir = tempname();
    mkdir(tmpdir);

    % Use Windows' built-in tar.exe to extract the xlsx (which is a ZIP archive).
    % tar.exe is available on Windows 10 1803+ and handles zip format natively.
    % This avoids the need for the 'unzip' binary that Octave's io package requires.
    abs_filename = make_absolute_filename(filename);
    cmd = sprintf('tar -xf "%s" -C "%s"', abs_filename, tmpdir);
    [status, output] = system(cmd);
    if status ~= 0
        % Fallback: try 'unzip' just in case it's available
        cmd2 = sprintf('unzip -o "%s" -d "%s"', abs_filename, tmpdir);
        [status2, output2] = system(cmd2);
        if status2 ~= 0
            rmdir(tmpdir, 's');
            error('readXlsxNative: Cannot extract "%s".\ntar error: %s\nunzip error: %s', ...
                filename, output, output2);
        end
    end

    % Clean up temp dir on exit (even on error)
    % Note: onCleanup requires Octave 4.0+
    cleanup = onCleanup(@() rmdir(tmpdir, 's'));

    % --- Step 1: Read shared strings table ---
    sharedStrings = {};
    ssFile = fullfile(tmpdir, 'xl', 'sharedStrings.xml');
    if exist(ssFile, 'file')
        fid = fopen(ssFile, 'r');
        ssXml = fread(fid, '*char')';
        fclose(fid);
        % Extract all <t>...</t> values from <si> entries
        % Some entries have <t xml:space="preserve"> so we handle that
        tokens = regexp(ssXml, '<t[^>]*>([^<]*)</t>', 'tokens');
        sharedStrings = cellfun(@(x) x{1}, tokens, 'UniformOutput', false);
    end

    % --- Step 2: Find the correct sheet file ---
    % Read workbook.xml to map sheet names to rId
    wbFile = fullfile(tmpdir, 'xl', 'workbook.xml');
    fid = fopen(wbFile, 'r');
    wbXml = fread(fid, '*char')';
    fclose(fid);

    % Find sheet name -> rId mapping
    % Pattern: <sheet name="options" sheetId="1" r:id="rId1"/>
    sheetPattern = ['<sheet[^>]*name="' sheetName '"[^>]*r:id="(rId\d+)"'];
    rIdMatch = regexp(wbXml, sheetPattern, 'tokens');
    if isempty(rIdMatch)
        % Try case-insensitive match
        rIdMatch = regexp(wbXml, sheetPattern, 'tokens', 'ignorecase');
    end
    if isempty(rIdMatch)
        error('readXlsxNative: Sheet "%s" not found in workbook', sheetName);
    end
    rId = rIdMatch{1}{1};

    % Read workbook.xml.rels to map rId -> filename
    relsFile = fullfile(tmpdir, 'xl', '_rels', 'workbook.xml.rels');
    fid = fopen(relsFile, 'r');
    relsXml = fread(fid, '*char')';
    fclose(fid);

    relPattern = ['Id="' rId '"[^>]*Target="([^"]+)"'];
    targetMatch = regexp(relsXml, relPattern, 'tokens');
    if isempty(targetMatch)
        error('readXlsxNative: Cannot resolve %s to a worksheet file', rId);
    end
    sheetFile = fullfile(tmpdir, 'xl', strrep(targetMatch{1}{1}, '/', filesep));

    % --- Step 3: Parse the sheet XML ---
    fid = fopen(sheetFile, 'r');
    sheetXml = fread(fid, '*char')';
    fclose(fid);

    % Extract all <row> elements
    rows = regexp(sheetXml, '<row[^>]*>(.*?)</row>', 'tokens');

    if isempty(rows)
        allCells = {};
        return;
    end

    % Parse each cell: <c r="A1" t="s"><v>0</v></c>
    % t="s" means shared string index, t="inlineStr" means inline,
    % no t or t="n" means number, t="b" means boolean
    maxRow = 0;
    maxCol = 0;
    cellData = {};  % will store {row, col, value} tuples

    for i = 1:length(rows)
        rowXml = rows{i}{1};
        % Match cells with content: <c r="A1" t="s"><v>0</v></c>
        cells = regexp(rowXml, '<c\s+([^>]*)>(.*?)</c>', 'tokens');
        % Also handle self-closing cells: <c r="A1" t="s"/>
        cellsSelfClose = regexp(rowXml, '<c\s+([^/]*)/>', 'tokens');

        allCellMatches = [cells, cellsSelfClose];

        for j = 1:length(allCellMatches)
            attrs = allCellMatches{j}{1};
            if length(allCellMatches{j}) > 1
                content = allCellMatches{j}{2};
            else
                content = '';
            end

            % Get cell reference (e.g., "A1", "B3")
            refMatch = regexp(attrs, 'r="([A-Z]+)(\d+)"', 'tokens');
            if isempty(refMatch)
                continue;
            end
            colStr = refMatch{1}{1};
            rowNum = str2double(refMatch{1}{2});

            % Convert column letter(s) to number (A=1, B=2, ..., AA=27, etc.)
            colNum = 0;
            for k = 1:length(colStr)
                colNum = colNum * 26 + (double(colStr(k)) - double('A') + 1);
            end

            maxRow = max(maxRow, rowNum);
            maxCol = max(maxCol, colNum);

            % Get cell type
            typeMatch = regexp(attrs, 't="([^"]*)"', 'tokens');
            if ~isempty(typeMatch)
                cellType = typeMatch{1}{1};
            else
                cellType = 'n';  % default is number
            end

            % Get value from <v>...</v>
            valMatch = regexp(content, '<v>([^<]*)</v>', 'tokens');
            if ~isempty(valMatch)
                rawVal = valMatch{1}{1};
            else
                rawVal = '';
            end

            % Convert based on type
            if strcmp(cellType, 's')
                % Shared string reference
                idx = str2double(rawVal) + 1;  % 0-indexed -> 1-indexed
                if idx >= 1 && idx <= length(sharedStrings)
                    cellValue = sharedStrings{idx};
                else
                    cellValue = '';
                end
            elseif strcmp(cellType, 'inlineStr')
                % Inline string: <is><t>value</t></is>
                isMatch = regexp(content, '<t[^>]*>([^<]*)</t>', 'tokens');
                if ~isempty(isMatch)
                    cellValue = isMatch{1}{1};
                else
                    cellValue = '';
                end
            elseif strcmp(cellType, 'b')
                % Boolean
                cellValue = str2double(rawVal);
            else
                % Number
                if ~isempty(rawVal)
                    numVal = str2double(rawVal);
                    if ~isnan(numVal)
                        cellValue = numVal;
                    else
                        cellValue = rawVal;
                    end
                else
                    cellValue = '';
                end
            end

            cellData{end+1} = {rowNum, colNum, cellValue}; %#ok<AGROW>
        end
    end

    % --- Step 4: Assemble into cell array ---
    allCells = cell(maxRow, maxCol);
    % Fill with empty string for compatibility (matches xlsread 3rd output)
    % xlsread returns '' for empty cells, not NaN
    for r = 1:maxRow
        for c = 1:maxCol
            allCells{r, c} = '';
        end
    end

    for i = 1:length(cellData)
        r = cellData{i}{1};
        c = cellData{i}{2};
        allCells{r, c} = cellData{i}{3};
    end

end
