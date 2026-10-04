import { PageHeading } from './ui';
const posts = [
  { title: 'Why Discipline Builds Champions', body: 'Every round in the ring starts long before the bell. The habits young athletes build at Junior Boy Boxing — showing up on time, listening to coaching, pushing through a hard set — carry over into school, friendships and family life. Boxing teaches that progress comes from consistency, not shortcuts.' },
  { title: 'Getting Started: What To Expect In Your First Class', body: 'New to boxing? Your first session focuses on the fundamentals: stance, footwork and basic combinations. Coach Sharif keeps class sizes small so every athlete gets personal attention. Wear comfortable athletic clothes, bring water, and come ready to learn — gloves and wraps are provided for beginners.' },
  { title: 'Confidence Beyond The Gym', body: 'Parents often tell us the biggest change they see isn’t physical — it’s how their child carries themselves afterward. Boxing builds self-control and focus under pressure, skills that help on test day as much as on fight day.' },
];
export function BlogPage() {
  return <div className="container page-wrap"><PageHeading eyebrow="From the corner" title="Blog.">Stories, tips and updates from Junior Boy Boxing.</PageHeading><div className="stack" style={{maxWidth:720}}>{posts.map(p=><article className="card" key={p.title}><h3>{p.title}</h3><p className="muted" style={{lineHeight:1.7}}>{p.body}</p></article>)}</div></div>;
}
