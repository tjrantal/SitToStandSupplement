% ----- Local function PARSECHILDNODES -----
function children = parseChildNodes(theNode)
	% Recurse over node children.
	children = [];
	if theNode.hasChildNodes
		%disp('Node has child');
	   childNodes = theNode.getChildNodes;
	   numChildNodes = childNodes.getLength;
	   allocCell = cell(1, numChildNodes);

	   children = struct(             ...
		  'Name', allocCell, 'Attributes', allocCell,    ...
		  'Data', allocCell, 'Children', allocCell);


		for count = 1:numChildNodes
			theChild = childNodes.item(count-1);
			%disp('Child make Struct from node');
			children(count) = makeStructFromNode(theChild);
		end
	end