using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace webApi.Core.Entidades
{
   public class Presentations
    {
        public int PresentationId { get; set; }
        public string PresentationDescription { get; set; }
        public string UnitMeasure {  get; set; }
        public int Quantity { get; set; }
        public bool IsActive { get; set; }
    }
}
