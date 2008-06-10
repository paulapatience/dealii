//----------------------------  mesh_3d_22.cc  ---------------------------
//    $Id: mesh_3d_22.cc 15662 2008-01-24 05:31:14Z kanschat $
//    Version: $Name$ 
//
//    Copyright (C) 2006, 2008 by Timo Heister and the deal.II authors
//
//    This file is subject to QPL and may not be  distributed
//    without copyright and license information. Please refer
//    to the file deal.II/doc/license.html for the  text  and
//    further information on this license.
//
//----------------------------  mesh_3d_22.cc  ---------------------------


// an adaptation of the deal.II/interpolate_q_01 test.  check that
// VectorTools::interpolate works for FE_Q(p) elements correctly on a mesh
// with a cell that has a wrong face orientation. when using a MappingQ(3), we
// calculated interpolation points wrongly

#include "../tests.h"

#include <grid/tria.h>
#include <grid/tria_accessor.h>
#include <grid/tria_iterator.h>
#include <grid/grid_generator.h>
#include <grid/tria_boundary_lib.h>
#include <grid/grid_out.h>
#include <grid/grid_in.h>
#include <lac/vector.h>
#include <numerics/data_out.h>
#include <base/quadrature_lib.h>
#include <fe/mapping_q.h>
#include <fe/fe_q.h>
#include <fstream>
#include <cmath>
#include <base/function.h>
#include <base/logstream.h>
#include <base/quadrature_lib.h>
#include <lac/vector.h>

#include <grid/tria.h>
#include <dofs/dof_handler.h>
#include <grid/grid_generator.h>
#include <grid/grid_refinement.h>
#include <grid/tria_accessor.h>
#include <grid/tria_iterator.h>
#include <grid/tria_boundary_lib.h>
#include <dofs/dof_accessor.h>
#include <dofs/dof_tools.h>
#include <numerics/vectors.h>
#include <fe/fe_q.h>

#include <fstream>
#include <vector>

using namespace dealii;
using namespace std;

template <int dim>
class F :  public Function<dim>
{
  public:
    F (const unsigned int q) : q(q) {}

    virtual double value (const Point<dim> &p,
			  const unsigned int) const
      {
	double v=0;
	for (unsigned int d=0; d<dim; ++d)
	  for (unsigned int i=0; i<=q; ++i)
	    v += (d+1)*(i+1)*std::pow (p[d], 1.*i);
	return v;
      }

  private:
    const unsigned int q;
};



template <int dim>
void test (Triangulation<dim>& triangulation)
{
  MappingQ<3> mapping(3);
  for (unsigned int p=1; p<7-dim; ++p)
    {
      FE_Q<dim>              fe(p);
      DoFHandler<dim>        dof_handler(triangulation);
      dof_handler.distribute_dofs (fe);

      Vector<double> interpolant (dof_handler.n_dofs());
      Vector<float>  error (triangulation.n_active_cells());
      for (unsigned int q=0; q<=p+2; ++q)
	{
					   // interpolate the function
	  VectorTools::interpolate (mapping, dof_handler,
				    F<dim> (q),
				    interpolant);

					   // then compute the interpolation error
	  VectorTools::integrate_difference (mapping, dof_handler,
					     interpolant,
					     F<dim> (q),
					     error,
					     QGauss<dim>(q+2),
					     VectorTools::L2_norm);
	  std::cout << fe.get_name() << ", P_" << q
		    << ", rel. error=" << error.l2_norm() / interpolant.l2_norm()
		    << " " << (((q<=p)&&!(error.l2_norm() < 1e-12*interpolant.l2_norm()))?"ASSERT":"")
		    << std::endl;
	  if (q<=p)
	    Assert (error.l2_norm() < 1e-12*interpolant.l2_norm(),
		    ExcInternalError());
	}
    }
}




int main ()
{
  deallog.depth_console(0);
  deallog.threshold_double(1.e-10);

  Triangulation<3> triangulation;
  GridIn<3> grid_in;
  grid_in.attach_triangulation(triangulation);
  std::ifstream inputStream("mesh_3d_22/mesh");
  grid_in.read(inputStream);
  test<3>(triangulation);


/*  
  MappingQ<3> mapping(3);

  FE_Q<3> fe(3);
  DoFHandler<3> dofh(triangulation);


  dofh.distribute_dofs(fe);

  {
    Vector<double> x(dofh.n_dofs());
    DataOut<3> data_out;

    data_out.attach_dof_handler(dofh);
    data_out.add_data_vector(x, "u");
    data_out.build_patches(mapping, 3);

    std::ofstream output("out.gpl");
    data_out.write(output, data_out.parse_output_format("gnuplot"));
  }

  Point<3> p;
  for (double x=0;x<=1;x+=1.0/3.0)
    {
      p(0)=x;
      p(1)=1.0/3.0;
      p(2)=0.0;

      Point<3> r=mapping.transform_unit_to_real_cell(++triangulation.begin_active(),p);
      std::cout << p << " > " << r << std::endl;
    }
*/
}

