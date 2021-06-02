function p = parse_filename(filename, fields, verbose)
  %
  % Split a filename into its building constituents
  %
  % USAGE::
  %
  %   p = bids.internal.parse_filename(filename, fields)
  %
  % :param filename: fielname to parse that follows the pattern
  %                  ``sub-label[_entity-label]*_suffix.extension``
  % :type  filename: string
  % :param fields:   cell of strings of the entities to use for parsing
  % :type  fields:   cell
  %
  % Example:
  %
  %   filename = '../sub-16/anat/sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz';
  %
  %   bids.internal.parse_filename(filename)
  %
  %   ans =
  %
  %   struct with fields:
  %
  %     'filename', 'sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz', ...
  %     'suffix', 'T1w', ...
  %     'ext', '.nii.gz', ...
  %     'entities', struct('sub', '16', ...
  %                        'ses', 'mri', ...
  %                        'run', '1', ...
  %                        'acq', 'hd');
  %
  %
  % (C) Copyright 2011-2018 Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  % (C) Copyright 2018 BIDS-MATLAB developers

  if nargin < 3 || isempty(verbose)
    verbose = false;
  end

  fields_order = {'filename', 'ext', 'suffix', 'entities', 'prefix'};

  filename = bids.internal.file_utils(filename, 'filename');

  % identify an eventual prefix to the file
  % only look for comes before the first "sub-"
  p.prefix = '';
  pos = strfind(filename, 'sub-');
  if ~isempty(pos) && pos(1) > 1
    p.prefix = filename(1:pos(1) - 1);
  else
    pos = 1;
  end
  basename = filename(pos:end);

  % -Identify all the BIDS entity-label pairs present in the filename (delimited by "_")
  [parts, dummy] = regexp(basename, '(?:_)+', 'split', 'match'); %#ok<ASGLU>
  p.filename = filename;

  % -Identify the suffix and extension of this file
  [p.suffix, p.ext] = strtok(parts{end}, '.');

  % -Separate the entity from the label for each pair identified above
  for i = 1:numel(parts) - 1
    [d, dummy] = regexp(parts{i}, '(?:\-)+', 'split', 'match'); %#ok<ASGLU>
    p.entities.(d{1}) = d{2};
  end

  % Extra fields can be added to the structure and ordered specifically.
  if nargin > 1
    for i = 1:numel(fields)
      p.entities = bids.internal.add_missing_field(p.entities, fields{i});
    end
    try
      p = orderfields(p, fields_order);
      p.entities = orderfields(p.entities, fields);
    catch
      msg = sprintf('Ignoring file %s not matching template.', filename);
      bids.internal.error_handling(mfilename, 'noMatchingTemplate', msg, true, verbose);
      p = struct([]);
    end
  end

end
