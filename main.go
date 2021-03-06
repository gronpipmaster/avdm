package main

import (
	"encoding/json"
	"encoding/xml"
	"fmt"
	"github.com/codegangsta/cli"
	"github.com/dustin/go-humanize"
	"github.com/shirou/gopsutil/disk"
	"github.com/shirou/gopsutil/load"
	"github.com/shirou/gopsutil/mem"
	"log"
	"os"
	"strings"
	"text/tabwriter"
	"text/template"
	"time"
)

var version string

func main() {
	app := cli.NewApp()
	app.Name = "avdm"
	app.EnableBashCompletion = true
	app.Author = "gronpipmaster"
	app.Version = version
	app.Flags = []cli.Flag{
		cli.BoolFlag{
			Name:  "human-readable, m",
			Usage: "print sizes in human readable format (e.g., 1K 234M 2G)",
		},
		cli.StringFlag{
			Name:  "format, f",
			Value: "text",
			Usage: "text, json, xml",
		},
	}
	app.Usage = "System info, avg free space and memory usage aka (avg + free + df)"
	app.Action = func(ctx *cli.Context) {
		s, err := getSystemInfo(ctx)
		if err != nil {
			log.Fatalln(err)
		}
		if ctx.String("format") != "text" {
			fmt.Println(s)
		} else {
			fmt.Print(s)
		}

		os.Exit(0)
	}
	app.Run(os.Args)
}

const tmplSystemInfo string = `{{.Now}}, load average: {{.Avg}}
{{ "\t" }}Total{{ "\t" }}Used{{ "\t" }}Free{{ "\t" }}Percent
Memory{{ "\t" }}{{human .Memory.Virtual.Total}}{{ "\t" }}{{human .Memory.Virtual.Used}}{{ "\t" }}{{human .Memory.Virtual.Free}}{{ "\t" }}{{.Memory.Virtual.UsedPercent}}%
Swap{{ "\t" }}{{human .Memory.Swap.Total}}{{ "\t" }}{{human .Memory.Swap.Used}}{{ "\t" }}{{human .Memory.Swap.Free}}{{ "\t" }}{{.Memory.Swap.UsedPercent}}%
Fs{{ "\t" }}{{ "\t" }}{{ "\t" }}{{ "\t" }}
{{range .Disks}}{{.Mountpoint}}{{ "\t" }}{{human .Total}}{{ "\t" }}{{human .Used}}{{ "\t" }}{{human .Free}}{{ "\t" }}{{.UsedPercent}}%
{{end}}`

type SystemInfo struct {
	Now    string `json:"now"`
	Disks  []Disk `json:"disks"`
	Memory struct {
		Virtual Info `json:"virtual"`
		Swap    Info `json:"swap"`
	} `json:"memory"`
	Avg string `json:"avg"`
	ctx *cli.Context
}

func (s *SystemInfo) String() string {
	switch s.ctx.String("format") {
	case "json":
		jsonStr, _ := json.Marshal(s)
		return string(jsonStr)
	case "xml":
		xmlStr, _ := xml.Marshal(s)
		return string(xmlStr)
	}
	funcMap := template.FuncMap{
		"human": func(value uint64) string {
			if s.ctx.Bool("human-readable") && value != 0 {
				return humanize.Bytes(value)
			} else {
				return fmt.Sprint(value / 1000)
			}
		},
	}
	w := tabwriter.NewWriter(os.Stdout, 0, 8, 1, '\t', 0)
	t := template.Must(template.New("systemInfo").Funcs(funcMap).Parse(tmplSystemInfo))
	err := t.Execute(w, s)
	if err != nil {
		panic(err)
	}
	w.Flush()
	return ""
}

type Info struct {
	Total       uint64 `json:"total"`
	Used        uint64 `json:"used"`
	Free        uint64 `json:"free"`
	UsedPercent int    `json:"usedPercent"`
}

type Disk struct {
	Device     string `json:"device"`
	Mountpoint string `json:"mountpoint"`
	Info
}

func getSystemInfo(c *cli.Context) (sys *SystemInfo, err error) {
	sys = new(SystemInfo)
	sys.ctx = c
	sys.Now = time.Now().Format(time.RFC822)
	partitions, err := disk.DiskPartitions(false)
	if err != nil {
		return
	}
	for _, partition := range partitions {
		if strings.HasPrefix(partition.Device, "/dev/") {
			diskInfo, err := disk.DiskUsage(partition.Mountpoint)
			if err != nil {
				return nil, err
			}
			disk := Disk{
				Device:     partition.Device,
				Mountpoint: partition.Mountpoint,
			}
			disk.Total = diskInfo.Total
			disk.Used = diskInfo.Used
			disk.Free = diskInfo.Free
			disk.UsedPercent = int(diskInfo.UsedPercent)
			sys.Disks = append(sys.Disks, disk)
		}
	}
	avg, err := load.LoadAvg()
	if err != nil {
		return
	}
	sys.Avg = fmt.Sprint(avg.Load1) + ", " + fmt.Sprint(avg.Load5) + ", " + fmt.Sprint(avg.Load15)

	memory, err := mem.VirtualMemory()
	if err != nil {
		return
	}
	memoryUsed := (memory.Used - memory.Buffers - memory.Cached)
	memoryFree := memory.Total - memoryUsed
	sys.Memory.Virtual = Info{
		Total:       memory.Total,
		Used:        memoryUsed,
		Free:        memoryFree,
		UsedPercent: int(memory.UsedPercent),
	}

	swap, err := mem.SwapMemory()
	if err != nil {
		return
	}
	sys.Memory.Swap = Info{
		Total:       swap.Total,
		Used:        swap.Used,
		Free:        swap.Free,
		UsedPercent: int(swap.UsedPercent),
	}

	return
}
