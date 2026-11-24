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
const extra={text:'Join and record',enabled:true,hasChildren:false,isSeparator:false};
const known={text:'Ask Yogurt',enabled:true,hasChildren:false,isSeparator:false};
assert.deepEqual(m.extraActions([known,extra,{text:'Recording · Example',enabled:false},{text:'Recent',enabled:true,hasChildren:true},{isSeparator:true,enabled:true}],labels),[extra]);
assert.equal(m.roleFor('Settings…',labels),'settings');assert.equal(m.roleFor('Quit Yogurt',labels),'quit');
assert.equal(m.pick([known],'ask',labels),known);

// The native calendar menu puts private event titles in enabled extra actions.
const catalog=require('../i18n/en.json');
const hiddenLabel=catalog['toolbar.meeting'],hiddenDescription=catalog['toolbar.meeting.description'];
const secret='Confidential acquisition — <b>Board discussion</b> 🗓';
let calendarFired=0;
const calendar={text:secret,enabled:true,triggered:()=>calendarFired++};
assert.equal(m.extraActions([entry,calendar],labels)[0],calendar);
for(const title of [secret,'📅 Current meeting: Private medical appointment','Upcoming: Client contract negotiation']) {
    const hidden=m.extraActionText(title,true,hiddenLabel,hiddenDescription);
    assert.deepEqual(hidden,{label:hiddenLabel,description:hiddenDescription});
    assert(!JSON.stringify(hidden).includes(title));
    assert.equal(m.tooltipText(hidden.description),hiddenDescription);
    assert.deepEqual(m.extraActionText(title,false,hiddenLabel,hiddenDescription),{label:title.slice(0,24),description:title.slice(0,160)});
    assert.deepEqual(m.extraActionText(title,true,hiddenLabel,hiddenDescription),hidden);
}
m.extraActions([calendar],labels)[0].triggered();assert.equal(calendarFired,1);
console.log('Passed: calendar title privacy, tooltip/accessibility presentation, toggling and unchanged native actions.');
