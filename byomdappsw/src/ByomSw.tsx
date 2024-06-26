
import "./styles/Home.module.css";
import { ByomSwLogin } from './components/ByomSwLogin';
import Navbar from './components/Navbar';

export default function App() {
  return (
    <main className="main">
      <div className="container">
        <div className="header">
          <h1 className="title">
             ${" "}
            <span className="gradient-text-0">
              <a
                href="https://thirdweb.com/"
                target="_blank"
                rel="noopener noreferrer"
              >
                BYOM
              </a>
            </span>
          </h1>
          <div>
            <Navbar/>
            <ByomSwLogin/>
          </div>
        </div>
      </div>
    </main>
  );
}
