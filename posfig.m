function fignumbo=posfig(fignumb,Pos,titl)
% POSFIG(FIGNUMB,POS,TITL)
%	Function to create and position a figure on screen according to the
%	figures current number FIGNUMB and default position POS
%	Also adds an optional title
%   Written by Toste Tanhua

if nargin <1 fignumb=[]; end
if nargin <2 Pos=get(0,'defaultfigureposition'); end
if nargin <3 titl=''; end

defunits='pixels'; fact=30;
oldunits=defunits;

%if Pos(3) < 14, units='inches'; fact=.3; end

iexst=0;
if ~isempty(fignumb),
  if find(fignumb==get(0,'chil'))>0, % figunmb already exists
    oldunits=get(fignumb,'units');
    set(fignumb,'units',defunits);
    Posexst=get(fignumb,'pos');
    Pos=[Posexst(1:2) Pos(3:4)];
    iexst=1;
  end
  
  figure(fignumb); 
else
  fignumb=figure; 
end
set(fignumb,'papertype','a4','paperunits','centimeters','paperposition',[0 0 14.8 19.6]);
set(fignumb,'Papertype','A4');set(gca,'fontname','arial','fontsize',8)

whitebg(fignumb,'w'); clf;

if iexst~=1,
  Pos(1)=Pos(1)-fact*(fignumb-1);
  Pos(2)=Pos(2)-fact*(fignumb-1);
end

% Make sure figure stays in the screen window
%
Screen=get(0,'ScreenSi');

Pos(1)=min(Pos(1),Screen(3)-Pos(3)); Pos(1)=max(Pos(1),0);
Pos(2)=min(Pos(2),Screen(4)-Pos(4)); Pos(2)=max(Pos(2),0);

set(fignumb,'Units',defunits , 'Position',Pos , 'Name',titl , 'Units',oldunits);

%% Set some nice defaults for the figure (FontSize, LineWidth etc.)
%graphdefault

if nargout>0
  fignumbo=fignumb;
end

return
