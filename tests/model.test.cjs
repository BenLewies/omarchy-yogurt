const assert=require('node:assert/strict');const m=require('../Model.js'),{labels}=require('../NativeLabels.js');
assert.equal(m.roleFor('Start recording',labels),'start');assert.equal(m.roleFor('Finish recording',labels),'stop');
for(const [role,phrases] of Object.entries(labels))for(const phrase of phrases)assert.equal(m.roleFor(phrase,labels),role);
assert.equal(m.elapsed(1000,62000),'01:01');assert.equal(m.elapsed(1000,3662000),'1:01:01');assert.equal(m.elapsed(2000,1000),'00:00');
assert.equal(m.tooltipText('<img src="https://tracker/"> & title').includes('<'),false);
assert.equal(m.literal('<b>Meeting</b>'),'<b>Meeting</b>');
assert.deepEqual(m.safeCommand(['gtk-launch','yogurt']),['gtk-launch','yogurt']);assert.deepEqual(m.safeCommand('sh -c unsafe'),[]);assert.deepEqual(m.safeCommand(['bad\0command']),[]);
let fired=0;const entry={text:'Start recording',enabled:true,triggered:()=>fired++};m.pick([entry],'start',labels).triggered();assert.equal(fired,1);assert.equal(m.pick([entry],'stop',labels),null);
console.log('Passed: native menu control mapping, translated menu labels, timer boundaries, safe arguments and markup-shaped metadata.');

assert(m.isYogurt({id:"Yogurt_status_icon_1",title:"",tooltipTitle:"Yogurt"}));
assert(m.isYogurt({id:"other",title:"",tooltipTitle:"Yogurt · 00:30"}));
assert(!m.isYogurt({id:"unrelated",title:"Something else"}));

assert.equal(m.modeFor(true,false,false),'ready');
assert.equal(m.modeFor(true,true,false),'recording');
assert.equal(m.modeFor(true,true,true),'paused');
assert.equal(m.modeFor(false,false,false),'offline');
