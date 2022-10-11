import "./App.css";
import { useCallback, useEffect, useRef, useState } from "react";
import { Socket } from "phoenix";
import { Bar } from "react-chartjs-2";

export const options = {
  scales: {
    x: { stacked: true },
    y: { stacked: true },
  },
};

const activeProps = { label: "Active", backgroundColor: "rgb(75, 192, 192)" };
const deletedProps = { label: "Deleted", backgroundColor: "rgb(255, 99, 132)" };
// const otherColor = "rgb(53, 162, 235)";

const convertData = (data) => {
  const newData = {
    labels: [],
    datasets: [
      { ...activeProps, data: [] },
      { ...deletedProps, data: [] },
    ],
  };
  Object.entries(data).forEach(([segment, [active, deleted]]) => {
    newData.labels.push(segment);
    newData.datasets[0].data.push(active);
    newData.datasets[1].data.push(deleted);
  });
  return newData;
};

function App() {
  const channelRef = useRef(null);
  const [running, setRunning] = useState(null);
  const [data, setData] = useState(null);

  const start = useCallback(() => {
    channelRef.current.push("start_test", {}, 5000);
  }, []);

  const stop = useCallback(() => {
    channelRef.current.push("stop_test", {}, 5000);
  }, []);

  useEffect(() => {
    const socket = new Socket("ws://localhost:4000/metrics");
    socket.connect();

    const channel = socket.channel("segments");
    channel.join();

    channel.on("update_status", (message) => {
      setRunning(message.running);
    });

    channel.on("update_stats", (message) => {
      setData(convertData(message));
    });

    channelRef.current = channel;
    return () => {
      setTimeout(() => {
        socket.disconnect();
      }, 1000);
    };
  }, []);

  return (
    <>
      <div>
        <button type="button" onClick={start} disabled={running !== false}>
          Start
        </button>
        <button type="button" onClick={stop} disabled={running !== true}>
          Stop
        </button>
      </div>
      <div>{data && <Bar options={options} data={data} />}</div>
    </>
  );
}

export default App;
